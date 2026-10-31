//
//  PullToRefresh.swift
//  VILLE
//
//  Pull-to-refresh for the reels, built by hand so the brand's red dot can
//  stand in for the system spinner (`.refreshable`'s can't be replaced).
//
//  Pulling the first reel down opens a strip under the top bar, and the
//  dot in the bar grows with it (a light tap once it's fully open). Let go
//  then and the feeds refresh: the strip stays open, the dot breathes in
//  it, and once the new reviews are in, the reel slides back up.
//
//  Three pieces, used together:
//  - `pullToRefresh(_:height:action:)` on the ScrollView: follows the pull,
//    starts the refresh when it's let go, and waits for it.
//  - `pullToRefreshHold(_:height:)` on the ScrollView's content: keeps the
//    strip open while the refresh runs.
//  - `RefreshDot`, which the top bar draws.
//

import SwiftUI

/// Where a pull-to-refresh is, shared by the feed (which is pulled) and the
/// top bar (which draws the dot).
struct PullToRefreshState: Equatable {
    /// How far the first reel is pulled down, 0 to 1 (1 = far enough to refresh).
    var progress: CGFloat = 0
    /// A refresh started by a pull is running: the strip stays open and the
    /// dot breathes.
    var isRefreshing = false
}

extension View {
    /// Put on the ScrollView. `height` is both how far to pull and how tall
    /// the strip stays while refreshing. `action` is the refresh: the strip
    /// stays open until it returns.
    func pullToRefresh(
        _ state: Binding<PullToRefreshState>,
        height: CGFloat,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        modifier(PullToRefreshModifier(state: state, height: height, action: action))
    }

    /// Put on the ScrollView's content (after `scrollTargetLayout()`). While
    /// a pull refresh runs, the content sits `height` points lower, so the
    /// strip stays open. It only moves what's drawn: the scroll view, its
    /// pages and its bounce stay as they are.
    func pullToRefreshHold(_ state: PullToRefreshState, height: CGFloat) -> some View {
        let isHolding = state.isRefreshing
        return visualEffect { content, proxy in
            let top = proxy.frame(in: .scrollView).minY
            let page = proxy.bounds(of: .scrollView)?.height ?? 0
            return content.offset(y: isHolding ? PullHold.offset(height: height, top: top, page: page) : 0)
        }
    }
}

/// The hold's arithmetic, kept apart so the drawing closure (which runs off
/// the main actor) can call it.
private enum PullHold {
    /// How far to push the content down, for where it is now. `top` is the
    /// content's top edge in the scroll view: above 0 while pulled down,
    /// below 0 once paging on.
    nonisolated static func offset(height: CGFloat, top: CGFloat, page: CGFloat) -> CGFloat {
        if top >= 0 {
            // Pulled down: the reel never shows above the strip, so the
            // scroll view's bounce lands on it and pulling again starts there.
            return max(height - top, 0)
        }
        // Paging on to the next reel mid-refresh: the strip closes over that
        // page, so the next reel lands where it always does.
        return height * max(1 + top / max(page, 1), 0)
    }
}

private struct PullToRefreshModifier: ViewModifier {
    @Binding var state: PullToRefreshState
    let height: CGFloat
    let action: @MainActor () async -> Void

    /// How far the content is pulled down past the top, in points.
    @State private var distance: CGFloat = 0

    private static let animation = Animation.spring(response: 0.4, dampingFraction: 0.8)

    func body(content: Content) -> some View {
        content
            // Only a pull past the top counts: everywhere else this stays 0
            // and nothing redraws.
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
            } action: { _, pull in
                distance = pull
                state.progress = min(pull / max(height, 1), 1)
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                // Letting go far enough down refreshes; a fling back up doesn't.
                guard oldPhase == .interacting, newPhase != .interacting, distance >= height else { return }
                start(fromPull: true)
            }
            .sensoryFeedback(trigger: state.progress >= 1) { _, isArmed in
                isArmed && !state.isRefreshing ? .impact(weight: .light) : nil
            }
            .accessibilityAction(named: "Refresh") { start(fromPull: false) }
    }

    /// Opens the strip (or keeps it open) and refreshes. New reviews join
    /// upcoming reels, never the one on screen.
    private func start(fromPull: Bool) {
        guard !state.isRefreshing else { return }
        // After a pull the strip is already open, so no animation: the hold
        // then follows the scroll view's bounce exactly. From VoiceOver's
        // Refresh action, the strip slides open.
        withAnimation(fromPull ? nil : Self.animation) {
            state.isRefreshing = true
        }
        Task {
            await action()
            withAnimation(Self.animation) {
                state.isRefreshing = false
            }
        }
    }
}

/// The pull-to-refresh indicator, in place of the system spinner: the
/// brand's red dot. It grows as the first reel is pulled down, then breathes
/// like the wordmark's dot until the new reviews are in.
struct RefreshDot: View {
    /// How far the pull has gone, 0 to 1.
    let progress: CGFloat
    let isRefreshing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PhaseAnimator(isRefreshing && !reduceMotion ? [1, 0.2] : [1]) { opacity in
            Circle()
                .fill(Color.brandRed)
                .frame(width: 8, height: 8)
                .opacity(opacity)
        } animation: { _ in
            .easeInOut(duration: 0.8)
        }
        // A fresh animator when refreshing starts or stops, so the dot
        // settles at full color instead of breathing forever.
        .id(isRefreshing)
        .scaleEffect(isRefreshing ? 1 : progress)
        .opacity(isRefreshing ? 1 : progress)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRefreshing)
        .accessibilityHidden(true)
    }
}
