//
//  FeedEmptyState.swift
//  VILLE
//
//  What the feed shows when it has no reel: a first welcome, the loading
//  dot breathing while reviews arrive (the wordmark's dot steps aside for
//  it), or why there's nothing to read (Settings
//  → Reading can leave nothing to pick). Each message ends on "Add people".
//

import SwiftUI

struct FeedEmptyState: View {
    /// Why the feed has no reels.
    enum Reason {
        /// Nobody followed yet.
        case noMembers
        /// The feeds are downloading.
        case fetching
        /// Every review has been shown, and Settings shows each one once.
        case allSeen
        /// What's left is very short, and Settings hides that.
        case onlyShort
        /// The members followed have no written reviews.
        case noReviews

        init(hasMembers: Bool, isRefreshing: Bool, reviews: [Review], rules: ReadingRules) {
            if !hasMembers {
                self = .noMembers
            } else if isRefreshing {
                self = .fetching
            } else if reviews.isEmpty {
                self = .noReviews
            } else if rules.showsEachReviewOnce, !reviews.contains(where: { $0.lastShownAt == nil }) {
                self = .allSeen
            } else if rules.hidesShortReviews {
                self = .onlyShort
            } else {
                self = .noReviews
            }
        }
    }

    let reason: Reason
    /// Lets the People sheet zoom out of the button.
    let namespace: Namespace.ID
    let onAddPeople: () -> Void

    var body: some View {
        switch reason {
        case .noMembers:
            message(
                title: "Reviews, one at a time",
                text: "Add the Letterboxd members whose writing you want to read."
            )
        case .fetching:
            VStack(spacing: 18) {
                RefreshDot(progress: 1, isRefreshing: true)
                Text("Fetching reviews…")
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
        case .allSeen:
            message(
                title: "Nothing new yet",
                text: "Settings shows each review once, and you’ve seen them all. New ones arrive when your members post."
            )
        case .onlyShort:
            message(
                title: "Only short reviews so far",
                text: "Very short reviews are hidden in Settings. Add more people to fill your feed."
            )
        case .noReviews:
            message(
                title: "No written reviews yet",
                text: "The people you follow haven’t posted reviews recently. Add more people to fill your feed."
            )
        }
    }

    /// A headline with the red full stop, a line of serif text and the
    /// button.
    private func message(title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            EditorialHeadline(text: title)
                .multilineTextAlignment(.center)
            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.primary.opacity(0.65))
                .multilineTextAlignment(.center)
            Button("Add people", action: onAddPeople)
                .buttonStyle(.glassProminent)
                .matchedTransitionSource(id: FeedSheet.addPeople, in: namespace)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }
}
