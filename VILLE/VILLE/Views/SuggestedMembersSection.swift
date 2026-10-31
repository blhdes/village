//
//  SuggestedMembersSection.swift
//  VILLE
//
//  A few members to start with, on the People screen: five at a time from
//  `SuggestedMember`, shown until the user follows
//  `SuggestedMember.enoughMembers`. Adding one swaps in someone new;
//  shuffle shows a different five. Nothing is fetched until "Add".
//

import SwiftUI

struct SuggestedMembersSection: View {
    /// Usernames already followed — never suggested.
    let following: Set<String>
    /// Called after a suggestion is added, for the screen's success haptic.
    let onAdded: () -> Void

    @Environment(FeedViewModel.self) private var viewModel

    @State private var suggestions: [SuggestedMember]
    @State private var adding: Set<String> = []
    @State private var addError: String?
    @State private var shuffles = 0

    private static let shownCount = 5

    init(following: Set<String>, onAdded: @escaping () -> Void) {
        self.following = following
        self.onAdded = onAdded
        // SwiftUI keeps the first pick; later inits don't reshuffle.
        _suggestions = State(initialValue: SuggestedMember.pick(Self.shownCount, excluding: following))
    }

    /// Leaves out anyone followed meanwhile, e.g. typed into the field above.
    private var visible: [SuggestedMember] {
        suggestions.filter { !following.contains($0.username) }
    }

    var body: some View {
        Section {
            ForEach(visible) { suggestion in
                row(suggestion)
            }
        } header: {
            HStack {
                Text("Suggested")
                Spacer()
                Button("Show others", systemImage: "shuffle", action: shuffle)
                    .labelStyle(.iconOnly)
                    .sensoryFeedback(.selection, trigger: shuffles)
            }
        } footer: {
            if let addError {
                Text(addError).foregroundStyle(Color.brandRed)
            } else {
                Text("Critics, writers, filmmakers and creators who post reviews often.")
            }
        }
    }

    private func row(_ suggestion: SuggestedMember) -> some View {
        let isAdding = adding.contains(suggestion.username)

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.displayName)
                    .font(.system(.body, design: .serif))
                Text("@\(suggestion.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Borderless, so the link and the button each keep their own tap
            // instead of the whole row firing both.
            HStack(spacing: 20) {
                if let profileURL = suggestion.profileURL {
                    Link(destination: profileURL) {
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Open \(suggestion.displayName) on Letterboxd")
                }
                Button("Add") { add(suggestion) }
                    .buttonStyle(.borderless)
                    .disabled(isAdding)
                    // The spinner sits where the button was, so the row doesn't jump.
                    .opacity(isAdding ? 0 : 1)
                    .overlay {
                        if isAdding { ProgressView() }
                    }
                    .accessibilityLabel("Add \(suggestion.displayName)")
            }
        }
    }

    // MARK: Actions

    private func add(_ suggestion: SuggestedMember) {
        adding.insert(suggestion.username)
        addError = nil

        Task {
            defer { adding.remove(suggestion.username) }
            do {
                try await viewModel.addMember(suggestion.username)
                onAdded()
                replace(suggestion)
            } catch {
                print("SuggestedMembersSection: adding \(suggestion.username) failed — \(error)")
                addError = error.localizedDescription
                // A deleted or renamed account won't come back: offer someone else.
                if let rssError = error as? RSSError, case .userNotFound = rssError {
                    replace(suggestion)
                }
            }
        }
    }

    /// Swaps one suggestion for someone new, leaving the rest in place.
    private func replace(_ suggestion: SuggestedMember) {
        guard let index = suggestions.firstIndex(of: suggestion) else { return }
        let taken = following.union(suggestions.map(\.username))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let next = SuggestedMember.pick(1, excluding: taken).first {
                suggestions[index] = next
            } else {
                suggestions.remove(at: index)
            }
        }
    }

    /// A different five, avoiding the ones on screen while enough are left.
    private func shuffle() {
        let onScreen = Set(suggestions.map(\.username))
        var next = SuggestedMember.pick(Self.shownCount, excluding: following.union(onScreen))
        if next.count < Self.shownCount {
            next = SuggestedMember.pick(Self.shownCount, excluding: following)
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            suggestions = next
            addError = nil
        }
        shuffles += 1
    }
}
