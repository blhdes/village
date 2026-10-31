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

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.reelBackground.ignoresSafeArea()

                if session.queue.slots.isEmpty {
                    emptyState
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
                case .settings: SettingsView()
                }
            }
            .navigationTransition(.zoom(sourceID: sheet, in: sheetNamespace))
        }
        .task { await viewModel.refreshIfNeeded() }
        .onChange(of: reviewIDs, initial: true) {
            session.sync(with: reviews, length: sessionLength)
        }
        .onChange(of: sessionLength) { _, length in
            session.resize(to: length, reviews: reviews)
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

                SessionEndView(
                    reviewCount: slots.count,
                    memberCount: Set(slots.compactMap { lookup[$0.reviewID]?.username }).count,
                    unreadCount: reviews.count(where: { $0.lastShownAt == nil }),
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
            guard let firstNew = session.keepReading(with: reviews, length: sessionLength) else { return }
            currentPageID = firstNew
        }
    }

    /// Back after a break: a new session from the top, and fresh feeds.
    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .background:
            session.didLeave()
        case .active:
            guard session.didReturn() else { return }
            session.startNew(with: reviews, length: sessionLength)
            currentPageID = session.queue.slots.first?.id
            Task { await viewModel.refreshAll() }
        default:
            break
        }
    }

    // MARK: Empty states

    @ViewBuilder
    private var emptyState: some View {
        if members.isEmpty {
            emptyMessage(
                title: "Reviews, one at a time",
                message: "Add the Letterboxd members whose writing you want to read.",
                buttonTitle: "Add people"
            )
        } else if viewModel.isRefreshing {
            VStack(spacing: 18) {
                VILLEWordmark(size: 44, isPulsing: true)
                Text("Fetching reviews…")
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
        } else {
            emptyMessage(
                title: "No written reviews yet",
                message: "The people you follow haven't posted reviews recently. Add more people to fill your feed.",
                buttonTitle: "Add people"
            )
        }
    }

    /// A headline with the red full stop, a line of serif text and one button.
    private func emptyMessage(title: LocalizedStringKey, message: LocalizedStringKey, buttonTitle: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            EditorialHeadline(text: title)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.primary.opacity(0.65))
                .multilineTextAlignment(.center)
            Button(buttonTitle) { activeSheet = .addPeople }
                .buttonStyle(.glassProminent)
                .matchedTransitionSource(id: FeedSheet.addPeople, in: sheetNamespace)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
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
