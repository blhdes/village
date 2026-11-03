//
//  SuggestedMembersSection.swift
//  VILLE
//
//  A few members to start with, on the People screen: five at a time from
//  `SuggestedMember`, shown until the user follows
//  `SuggestedMember.enoughMembers`. Following one swaps in someone new;
//  shuffle shows a different five. Nothing is fetched until a name is
//  tapped, to read their reviews first, or "Follow" is.
//

import SwiftUI

struct SuggestedMembersSection: View {
    /// Usernames already followed — never suggested.
    let following: Set<String>
    /// Called after a suggestion is followed, for the screen's success haptic.
    let onFollowed: () -> Void
    /// Opens a suggestion's reviews, to read before following.
    let onRead: (SuggestedMember) -> Void

    @Environment(FeedViewModel.self) private var viewModel

    @State private var suggestions: [SuggestedMember]
    /// Suggestions being followed: their feed is downloading.
    @State private var pending: Set<String> = []
    @State private var followError: String?
    @State private var shuffles = 0

    private static let shownCount = 5

    init(following: Set<String>, onFollowed: @escaping () -> Void, onRead: @escaping (SuggestedMember) -> Void) {
        self.following = following
        self.onFollowed = onFollowed
        self.onRead = onRead
        // SwiftUI keeps the first pick; later inits don't reshuffle.
        _suggestions = State(initialValue: SuggestedMember.pick(Self.shownCount, excluding: following))
    }

    /// Leaves out anyone followed meanwhile, e.g. found by the search above
    /// or followed from their feed.
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
            if let followError {
                Text(followError).foregroundStyle(Color.brandRed)
            } else {
                Text("Critics, writers, filmmakers and creators who post reviews often. Tap a name to read their reviews before following.")
            }
        }
    }

    private func row(_ suggestion: SuggestedMember) -> some View {
        let isPending = pending.contains(suggestion.username)

        // Borderless, so the name, the link and the button each keep their
        // own tap instead of the whole row firing them all.
        return HStack {
            Button {
                onRead(suggestion)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.displayName)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Color.primary)
                    Text("@\(suggestion.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Opens their reviews")

            HStack(spacing: 20) {
                if let profileURL = suggestion.profileURL {
                    Link(destination: profileURL) {
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Open \(suggestion.displayName) on Letterboxd")
                }
                Button("Follow") { follow(suggestion) }
                    .buttonStyle(.borderless)
                    .disabled(isPending)
                    // The spinner sits where the button was, so the row doesn't jump.
                    .opacity(isPending ? 0 : 1)
                    .overlay {
                        if isPending { ProgressView() }
                    }
                    .accessibilityLabel("Follow \(suggestion.displayName)")
            }
        }
    }

    // MARK: Actions

    private func follow(_ suggestion: SuggestedMember) {
        pending.insert(suggestion.username)
        followError = nil

        Task {
            defer { pending.remove(suggestion.username) }
            do {
                try await viewModel.addMember(suggestion.username)
                onFollowed()
                replace(suggestion)
            } catch {
                print("SuggestedMembersSection: following \(suggestion.username) failed — \(error)")
                followError = error.localizedDescription
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
            followError = nil
        }
        shuffles += 1
    }
}
