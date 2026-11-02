//
//  MembersView.swift
//  VILLE
//
//  Add and remove the Letterboxd members whose reviews fill the feed.
//  Saved only on this device. Until the user follows a few people, a
//  "Suggested" section offers some to start with. Bookmarks open from here
//  too: one quiet row, the user's own corner of the library, with a
//  monochrome icon like the rows in Settings.
//

import SwiftUI
import SwiftData

/// Screens pushed from People. By value, like the reviews pushed from
/// Bookmarks: mixing view links and value links in one stack can pop the
/// Bookmarks list when a review opens.
private enum PeopleRoute: Hashable {
    case bookmarks
}

struct MembersView: View {
    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FollowedUser.addedAt, order: .reverse) private var members: [FollowedUser]
    @Query(filter: #Predicate<Review> { $0.bookmarkedAt != nil }) private var bookmarks: [Review]

    @State private var input = ""
    @State private var isAdding = false
    @State private var addError: String?
    @State private var addedCount = 0

    private var canAdd: Bool {
        !isAdding && !input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Letterboxd username or profile link", text: $input)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(add)

                        if isAdding {
                            ProgressView()
                        } else {
                            Button("Add", action: add)
                                .disabled(!canAdd)
                        }
                    }
                } footer: {
                    if let addError {
                        Text(addError).foregroundStyle(Color.brandRed)
                    } else {
                        Text("Only public reviews from Letterboxd RSS feeds are shown.")
                    }
                }

                if members.count < SuggestedMember.enoughMembers {
                    SuggestedMembersSection(following: Set(members.map(\.username))) {
                        addedCount += 1
                    }
                }

                Section {
                    NavigationLink(value: PeopleRoute.bookmarks) {
                        LabeledContent {
                            if !bookmarks.isEmpty {
                                Text(bookmarks.count, format: .number)
                            }
                        } label: {
                            Label {
                                Text("Bookmarks")
                                    .font(.system(.body, design: .serif))
                            } icon: {
                                Image(systemName: "bookmark")
                            }
                        }
                    }
                }

                if !members.isEmpty {
                    Section("Following") {
                        ForEach(members) { member in
                            memberRow(member)
                        }
                        .onDelete { offsets in
                            viewModel.removeMembers(offsets.map { members[$0] })
                        }
                    }
                }
            }
            .navigationDestination(for: PeopleRoute.self) { _ in
                BookmarksView()
            }
            .editorialTitle("People")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: addedCount)
        }
    }

    private func memberRow(_ member: FollowedUser) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.system(.body, design: .serif))
                Text("@\(member.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let profileURL = member.profileURL {
                Link(destination: profileURL) {
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                }
                .accessibilityLabel("Open \(member.displayName) on Letterboxd")
            }
        }
    }

    private func add() {
        guard canAdd else { return }
        let submitted = input
        isAdding = true
        addError = nil

        Task {
            defer { isAdding = false }
            do {
                try await viewModel.addMember(submitted)
                // Keep anything typed while waiting — it's the next member.
                if input == submitted { input = "" }
                addedCount += 1
            } catch {
                print("MembersView: adding \(submitted) failed — \(error)")
                addError = error.localizedDescription
            }
        }
    }
}
