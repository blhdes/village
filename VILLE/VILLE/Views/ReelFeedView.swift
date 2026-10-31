//
//  ReelFeedView.swift
//  VILLE
//
//  Main screen: full-screen reviews you swipe through vertically, one per
//  page, in the order kept by `ReelSession`. The last page is the session's
//  end card.
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

    @Query private var reviews: [Review]
    @Query private var members: [FollowedUser]

    @AppStorage(SettingsKey.showPosters) private var showPosters = true
    @AppStorage(SettingsKey.showBackdrops) private var showBackdrops = true
    @AppStorage(SettingsKey.alternativePosters) private var alternativePosters = false
    @AppStorage(SettingsKey.showRatings) private var showRatings = true
    @AppStorage(SettingsKey.sessionLength) private var sessionLength = SessionLength.standard

    /// The page on screen: a reel's slot id, or `ReelSession.endPageID`.
    @State private var currentPageID: Int?
    @State private var activeSheet: FeedSheet?
    /// How far the first reel is pulled down past the top, in points.
    @State private var pullDistance: CGFloat = 0
    /// A pull-to-refresh is running: the top bar's red dot breathes.
    @State private var isPullRefreshing = false

    /// How far to pull before letting go refreshes.
    private static let pullThreshold: CGFloat = 80

    private var pullProgress: CGFloat { min(pullDistance / Self.pullThreshold, 1) }

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
            ReelTopBar(
                namespace: sheetNamespace,
                pullProgress: pullProgress,
                isPullRefreshing: isPullRefreshing
            ) { activeSheet = $0 }
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
        // A refresh that was already running when the pull came in ends here.
        .onChange(of: viewModel.isRefreshing) { _, refreshing in
            if !refreshing { isPullRefreshing = false }
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
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        // Pull-to-refresh, built by hand so the brand's red dot can stand in
        // for the system spinner. Only a pull past the top of the first reel
        // counts: everywhere else this stays 0 and nothing redraws.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
        } action: { _, pull in
            pullDistance = pull
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            // Letting go far enough down refreshes; a fling back up doesn't.
            guard oldPhase == .interacting, newPhase != .interacting,
                  pullDistance >= Self.pullThreshold else { return }
            startPullRefresh()
        }
        .sensoryFeedback(trigger: pullProgress >= 1) { _, isArmed in
            isArmed && !isPullRefreshing ? .impact(weight: .light) : nil
        }
        .accessibilityAction(named: "Refresh") { startPullRefresh() }
    }

    /// Fetches every feed again; the top bar's red dot breathes until the
    /// new reviews are in. They join upcoming reels, never the one on screen.
    private func startPullRefresh() {
        guard !isPullRefreshing else { return }
        isPullRefreshing = true
        Task {
            await viewModel.refreshAll()
            // If a refresh was already running, this call returned at once;
            // the dot then waits for it (see the isRefreshing onChange).
            if !viewModel.isRefreshing { isPullRefreshing = false }
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
