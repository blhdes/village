//
//  MemberSearchSection.swift
//  VILLE
//
//  The top of People: search Letterboxd by username or link, including
//  the boxd.it short links the Letterboxd app shares. One request to the
//  member's RSS feed when the search is sent (`FeedViewModel.lookUp`),
//  never while typing. The member found shows with how many reviews their
//  feed holds: read them first (`MemberFeedView`), or follow.
//

import SwiftUI

struct MemberSearchSection: View {
    /// Usernames already followed.
    let following: Set<String>
    /// Called after the member found is followed, for the screen's success haptic.
    let onFollowed: () -> Void
    /// Opens the member found's reviews.
    let onRead: (FoundMember) -> Void

    @Environment(FeedViewModel.self) private var viewModel

    @State private var input = ""
    @State private var isSearching = false
    @State private var searchError: String?
    /// The member the last search found.
    @State private var found: FoundMember?

    private var canSearch: Bool {
        !isSearching && !input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Section {
            HStack {
                TextField("Letterboxd username or profile link", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(search)

                if isSearching {
                    ProgressView()
                } else {
                    Button("Search", action: search)
                        .disabled(!canSearch)
                }
            }

            if let found {
                result(found)
            }
        } footer: {
            if let searchError {
                Text(searchError).foregroundStyle(Color.brandRed)
            } else {
                Text("Only public reviews from Letterboxd RSS feeds are shown.")
            }
        }
    }

    /// The member found: their name and how many reviews their feed holds,
    /// then Read their reviews, and Follow.
    private func result(_ member: FoundMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.system(.body, design: .serif, weight: .semibold))
                Text("@\(member.username) · ^[\(member.reviewCount) recent review](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    Button("Read their reviews") { onRead(member) }
                        .buttonStyle(.glass)

                    if following.contains(member.username) {
                        FollowingBadge()
                    } else {
                        Button("Follow") { follow(member) }
                            .buttonStyle(.glassProminent)
                    }
                }
            }
            .font(.system(.subheadline, design: .serif, weight: .medium))
        }
        .padding(.vertical, 4)
    }

    // MARK: Actions

    private func search() {
        guard canSearch else { return }
        let submitted = input
        isSearching = true
        searchError = nil

        Task {
            defer { isSearching = false }
            do {
                let member = try await viewModel.lookUp(submitted)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    found = member
                }
            } catch {
                print("MemberSearchSection: searching for \(submitted) failed — \(error)")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    found = nil
                }
                searchError = error.localizedDescription
            }
        }
    }

    private func follow(_ member: FoundMember) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.follow(username: member.username, displayName: member.displayName)
        }
        onFollowed()
    }
}
