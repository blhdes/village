//
//  MemberFeedView.swift
//  VILLE
//
//  One member's reviews as reels, opened from People: someone found by
//  Search, a suggestion or someone followed. Their name stands where the
//  feed has "ville.", with Follow and Close where it has People and
//  Settings, and their feed ends on their name with the red full stop
//  (`MemberFeedCards`). Newest first, every review their feed holds.
//  "Hide very short reviews" applies, as in the feed; "Show each review
//  once" doesn't, and nothing here counts as shown (`Review.lastShownAt`),
//  so following them afterwards brings every review into the feed as new.
//
//  Their reviews are saved like any member's (`FeedViewModel.lookUp`), so
//  bookmarks, spoilers and translation work as in the feed. While nobody
//  follows them, they're deleted at the next launch (`LibraryTrimmer`),
//  bookmarks apart.
//

import SwiftUI
import SwiftData

/// A member's feed to open from People.
struct MemberVisit: Identifiable {
    let username: String
    let displayName: String
    /// Fetch their RSS feed first, as for a suggestion. False when Search
    /// has just fetched it, or for someone followed: their reviews are saved.
    let fetchesFeed: Bool

    var id: String { username }
}

struct MemberFeedView: View {
    let visit: MemberVisit

    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The member, once followed.
    @Query private var followed: [FollowedUser]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = false
    @AppStorage(SettingsKey.alternativePosters) private var alternativePosters = false
    @AppStorage(SettingsKey.showRatings) private var showRatings = true
    @AppStorage(SettingsKey.hideShortReviews) private var hideShortReviews = false

    @State private var stage = Stage.loading
    /// The name their feed gives, once fetched.
    @State private var name: String
    /// The reviews on show and their reels, fixed when the feed opens, so
    /// nothing moves while reading.
    @State private var reviews: [Review] = []
    @State private var slots: [ReelSlot] = []
    /// Their feed has reviews, but all very short, and Settings hides those.
    @State private var onlyShort = false
    @State private var currentPageID: Int?
    @State private var follows = 0

    private enum Stage: Equatable {
        case loading
        case ready
        case failed(String)
    }

    /// Scroll id of the card after their last review.
    private static let endPageID = -1

    init(visit: MemberVisit) {
        self.visit = visit
        let username = visit.username
        _followed = Query(filter: #Predicate<FollowedUser> { $0.username == username })
        _name = State(initialValue: visit.displayName)
    }

    private var isFollowed: Bool { !followed.isEmpty }

    /// Follow, on the cards, once their feed is in and until it's followed.
    private var followAction: (() -> Void)? {
        guard !isFollowed, stage == .ready else { return nil }
        return follow
    }

    private var look: ReelLook {
        ReelLook(
            showPoster: showPosters,
            showBackdrop: showBackdrops,
            alternativePosters: alternativePosters,
            showRating: showRatings
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.reelBackground.ignoresSafeArea()

                switch stage {
                case .loading:
                    MemberFeedLoading(name: name)
                case .failed(let message):
                    MemberFeedCard(headline: EditorialHeadline(verbatim: name), message: Text(message), isError: true, onFollow: nil) { dismiss() }
                case .ready:
                    if slots.isEmpty {
                        emptyCard
                    } else {
                        reels(insets: proxy.safeAreaInsets)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            bar
        }
        .task { await open() }
        .sensoryFeedback(.success, trigger: follows)
        // A firmer tap at the end of their feed, as at the end of a session.
        .sensoryFeedback(trigger: currentPageID) { _, pageID in
            pageID == Self.endPageID ? .success : .selection
        }
    }

    // MARK: Bar

    /// Their name where the feed has "ville.", then Follow and Close, where
    /// the feed has People and Settings.
    private var bar: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.system(.title3, design: .serif, weight: .semibold).italic())
                .lineLimit(1)

            Spacer(minLength: 0)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    followControl
                        .font(.system(.body, design: .serif, weight: .medium))

                    Button(role: .close) {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Close")
                }
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFollowed)
    }

    /// Follow, once their feed is in; "Following" once followed.
    @ViewBuilder
    private var followControl: some View {
        if isFollowed {
            FollowingBadge(labelHeight: 24)
        } else if stage == .ready {
            Button(action: follow) {
                Text("Follow")
                    .frame(height: 24)
            }
            .buttonStyle(.glassProminent)
        }
    }

    // MARK: Reels

    private func reels(insets: EdgeInsets) -> some View {
        let lookup = Dictionary(reviews.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(slots) { slot in
                    Group {
                        if let review = lookup[slot.reviewID] {
                            ReelView(review: review, slot: slot, look: look, insets: insets)
                        } else {
                            Color.reelBackground
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                }

                endCard
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(Self.endPageID)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
    }

    /// After their last review: their name, ending on the red full stop.
    private var endCard: some View {
        let message = isFollowed
            ? Text("You follow \(name): their new reviews arrive in your feed.")
            : Text("^[\(reviews.count) recent review](inflect: true) in their Letterboxd feed.")
        return MemberFeedCard(headline: EditorialHeadline(verbatim: name), message: message, onFollow: followAction) { dismiss() }
    }

    /// Nothing to read: no written reviews in their feed, or only very
    /// short ones, which Settings hides.
    @ViewBuilder
    private var emptyCard: some View {
        if onlyShort {
            MemberFeedCard(headline: EditorialHeadline(text: "Only short reviews so far"), message: Text("Very short reviews are hidden in Settings."), onFollow: followAction) { dismiss() }
        } else {
            MemberFeedCard(headline: EditorialHeadline(text: "No written reviews yet"), message: Text("Their recent activity on Letterboxd has no written reviews."), onFollow: followAction) { dismiss() }
        }
    }

    // MARK: Actions

    /// Fetches their feed when needed, then fixes the reels: newest first,
    /// without the very short ones if Settings hides them.
    private func open() async {
        guard stage == .loading else { return }

        if visit.fetchesFeed {
            do {
                name = try await viewModel.lookUp(username: visit.username).displayName
            } catch {
                print("MemberFeedView: could not fetch the feed of \(visit.username) — \(error)")
                // Reviews saved before (an earlier look, a bookmark) can still be read.
                guard !savedReviews().isEmpty else {
                    stage = .failed(error.localizedDescription)
                    return
                }
            }
        }

        let saved = savedReviews()
        let readable = hideShortReviews ? saved.filter { !$0.isVeryShort } : saved
        reviews = readable
        onlyShort = readable.isEmpty && !saved.isEmpty
        slots = readable.enumerated().map { index, review in
            ReelSlot(
                id: index,
                reviewID: review.id,
                backdropPick: Int.random(in: 0..<1_000),
                posterPick: Int.random(in: 0..<1_000)
            )
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            stage = .ready
        }
    }

    /// Their saved reviews, newest first.
    private func savedReviews() -> [Review] {
        let username = visit.username
        let descriptor = FetchDescriptor<Review>(
            predicate: #Predicate { $0.username == username },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("MemberFeedView: could not read the reviews of \(username) — \(error)")
            return []
        }
    }

    private func follow() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.follow(username: visit.username, displayName: name)
        }
        follows += 1
    }
}
