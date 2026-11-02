//
//  ReelFeedView.swift
//  VILLE
//
//  Main screen: full-screen reviews you swipe through vertically, one per
//  page, in the order kept by `ReelSession`. The last page is the session's
//  end card. Pulling the first reel down refreshes the feeds
//  (PullToRefresh.swift).
//

import SwiftUI
import SwiftData

/// The sheets the feed can open. `addPeople` opens the same screen as
/// `members`, but from the empty-state button, so the sheet zooms out of the
/// right place.
enum FeedSheet: String, Identifiable {
    case members, addPeople, settings
    var id: String { rawValue }
}

struct ReelFeedView: View {
    @Environment(FeedViewModel.self) private var viewModel
    @Environment(ReelSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    /// Lets each sheet zoom out of the button that opened it.
    @Namespace private var sheetNamespace

    /// Every saved review, including bookmarks from members removed since.
    @Query private var library: [Review]
    @Query private var members: [FollowedUser]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = true
    @AppStorage(SettingsKey.alternativePosters) private var alternativePosters = false
    @AppStorage(SettingsKey.showRatings) private var showRatings = true
    @AppStorage(SettingsKey.sessionLength) private var sessionLength = SessionLength.standard
    @AppStorage(SettingsKey.hideShortReviews) private var hideShortReviews = false
    @AppStorage(SettingsKey.showEachReviewOnce) private var showEachReviewOnce = false

    /// The page on screen: a reel's slot id, or `ReelSession.endPageID`.
    @State private var currentPageID: Int?
    @State private var activeSheet: FeedSheet?
    /// The pull-to-refresh, shared with the top bar's dot.
    @State private var pull = PullToRefreshState()
    /// Where the top bar ends, from the top of the screen.
    @State private var topBarBottom: CGFloat = 0

    /// The pull-to-refresh strip: down to just below the top bar, so while
    /// refreshing the dot breathes on the plain page, clear of the reel.
    private var pullHeight: CGFloat { max(topBarBottom + 12, 80) }

    /// What the feed can show: reviews by the members followed now. A
    /// bookmark from someone removed stays in Bookmarks, not here.
    private var reviews: [Review] {
        let followed = Set(members.map(\.username))
        return library.filter { followed.contains($0.username) }
    }

    private var reviewIDs: [String] { reviews.map(\.id) }

    /// Settings → Reading: how long a session is, and which reviews it
    /// leaves out.
    private var rules: ReadingRules {
        ReadingRules(
            length: sessionLength,
            hidesShortReviews: hideShortReviews,
            showsEachReviewOnce: showEachReviewOnce
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.reelBackground.ignoresSafeArea()

                if session.queue.slots.isEmpty {
                    FeedEmptyState(
                        reason: .init(hasMembers: !members.isEmpty, isRefreshing: viewModel.isRefreshing, reviews: reviews, rules: rules),
                        namespace: sheetNamespace
                    ) {
                        activeSheet = .addPeople
                    }
                } else {
                    reels(insets: proxy.safeAreaInsets)
                }
            }
        }
        .overlay(alignment: .top) {
            ReelTopBar(namespace: sheetNamespace, pull: pull) { activeSheet = $0 }
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { topBarBottom = $0 }
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .members, .addPeople: MembersView()
                case .settings: SettingsView(preview: settingsPreview)
                }
            }
            .navigationTransition(.zoom(sourceID: sheet, in: sheetNamespace))
        }
        .task { await viewModel.refreshIfNeeded() }
        .onChange(of: reviewIDs, initial: true) {
            session.sync(with: reviews, rules: rules)
        }
        .onChange(of: rules) { _, rules in
            session.apply(rules, reviews: reviews)
        }
        .onChange(of: currentPageID) { _, pageID in
            guard let pageID else { return }
            session.didShowPage(pageID, reviews: reviews)
        }
        .onChange(of: scenePhase) { _, phase in
            handle(phase)
        }
        // A firmer tap when the session ends.
        .sensoryFeedback(trigger: currentPageID) { _, pageID in
            pageID == ReelSession.endPageID ? .success : .selection
        }
        // On Fin cards: the third, then up to three more (`RatingRequest`).
        .asksForRating(finishedSessions: session.finishedSessions, onEndCard: currentPageID == ReelSession.endPageID)
    }

    // MARK: Reels

    private func reels(insets: EdgeInsets) -> some View {
        let lookup = Dictionary(reviews.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let look = ReelLook(
            showPoster: showPosters,
            showBackdrop: showBackdrops,
            alternativePosters: alternativePosters,
            showRating: showRatings
        )
        let slots = session.queue.slots
        // Never shown, and allowed by Settings → Reading.
        let unread = reviews.count { $0.lastShownAt == nil && rules.allows($0) }

        return ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(slots) { slot in
                    Group {
                        if let review = lookup[slot.reviewID] {
                            ReelView(review: review, slot: slot, look: look, insets: insets) {
                                unfollow(review.username, leaving: slot)
                            }
                        } else {
                            Color.reelBackground
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                }

                SessionEndView(
                    reviewCount: slots.count,
                    memberCount: Set(slots.compactMap { lookup[$0.reviewID]?.username }).count,
                    unreadCount: unread,
                    // Each review once and none left: the session can't go on.
                    canKeepReading: unread > 0 || !rules.showsEachReviewOnce,
                    onKeepReading: keepReading
                )
                .containerRelativeFrame([.horizontal, .vertical])
                .id(ReelSession.endPageID)
            }
            .scrollTargetLayout()
            // While a pull refresh runs, the reels wait below the strip.
            .pullToRefreshHold(pull, height: pullHeight)
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .pullToRefresh($pull, height: pullHeight) {
            await viewModel.refreshAll()
        }
    }

    /// The new session's reels take the end card's place; the card moves
    /// down to follow them.
    private func keepReading() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            guard let firstNew = session.keepReading(with: reviews, rules: rules) else { return }
            currentPageID = firstNew
        }
    }

    /// Unfollows a reel's author, from its byline. The feed first moves on
    /// to the next reel by someone else (or the end card), then the member
    /// and their saved reviews go, so nothing vanishes under the reader's
    /// eyes. Bookmarks stay.
    private func unfollow(_ username: String, leaving slot: ReelSlot) {
        guard let member = members.first(where: { $0.username == username }) else {
            print("ReelFeedView: \(username) isn't followed, nothing to unfollow")
            return
        }
        let authors = Dictionary(reviews.map { ($0.id, $0.username) }, uniquingKeysWith: { first, _ in first })
        let slots = session.queue.slots
        let after = slots.firstIndex { $0.id == slot.id }.map { $0 + 1 } ?? 0
        let next = slots[after...].first { upcoming in
            authors[upcoming.reviewID].map { $0 != username } ?? false
        }?.id ?? ReelSession.endPageID

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPageID = next
        } completion: {
            viewModel.removeMembers([member])
        }
    }

    /// The reel on screen, drawn at the top of Settings.
    private var settingsPreview: LookPreview.Sample? {
        .onScreen(
            in: session.queue,
            pageID: currentPageID,
            reviews: reviews,
            revealedSpoilers: session.revealedSpoilers
        )
    }

    /// Back after a break: a new session from the top, and fresh feeds.
    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .background:
            session.didLeave()
        case .active:
            guard session.didReturn() else { return }
            session.startNew(with: reviews, rules: rules)
            currentPageID = session.queue.slots.first?.id
            Task { await viewModel.refreshAll() }
        default:
            break
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Review.self, FollowedUser.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    ReelFeedView()
        .environment(FeedViewModel(context: container.mainContext))
        .environment(ReelSession(context: container.mainContext))
        .environment(ReviewTranslator())
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
