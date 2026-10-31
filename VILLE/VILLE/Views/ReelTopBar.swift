//
//  ReelTopBar.swift
//  VILLE
//
//  The bar over the feed: the VILLE wordmark on the left, People and
//  Settings on the right, the pull-to-refresh dot in the middle, and the
//  error banner that drops below them.
//

import SwiftUI

struct ReelTopBar: View {
    /// Lets each sheet zoom out of the button that opened it.
    let namespace: Namespace.ID
    /// How far the first reel is pulled down, 0 to 1 (1 = far enough to refresh).
    var pullProgress: CGFloat = 0
    /// A pull-to-refresh is running: the middle dot breathes instead of the wordmark's.
    var isPullRefreshing = false
    let open: (FeedSheet) -> Void

    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            // The red dot breathes while feeds refresh, unless the
            // pull-to-refresh dot is already showing it.
            VILLEWordmark(isPulsing: viewModel.isRefreshing && !isPullRefreshing)

            Spacer()

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    barButton("person.2", label: "People") { open(.members) }
                        .matchedTransitionSource(id: FeedSheet.members, in: namespace)
                    barButton("slider.horizontal.3", label: "Settings") { open(.settings) }
                        .matchedTransitionSource(id: FeedSheet.settings, in: namespace)
                }
            }
        }
        .padding(.horizontal, 20)
        .overlay {
            RefreshDot(progress: pullProgress, isRefreshing: isPullRefreshing)
        }
        .overlay(alignment: .bottom) {
            // Always on screen, so the banner's glass can form and dissolve
            // inside it instead of sliding in.
            GlassEffectContainer {
                errorBanner
            }
            .offset(y: 52)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage)
        }
    }

    private func barButton(_ systemImage: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                // Interactive: the glass reacts to touch, hinting it can be tapped away.
                .glassEffect(.regular.tint(Color.brandRed.opacity(0.4)).interactive(), in: .capsule)
                .glassEffectTransition(reduceMotion ? .identity : .materialize)
                .onTapGesture { viewModel.errorMessage = nil }
        }
    }
}

/// The pull-to-refresh indicator, in place of the system spinner: the
/// brand's red dot. It grows as the first reel is pulled down, then breathes
/// like the wordmark's dot until the new reviews are in.
private struct RefreshDot: View {
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
