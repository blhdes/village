//
//  ReelTopBar.swift
//  VILLE
//
//  The bar over the feed: the VILLE wordmark on the left, People and
//  Settings on the right, the pull-to-refresh dot in the middle
//  (`RefreshDot`, see PullToRefresh.swift), and the error banner that
//  drops below them.
//

import SwiftUI

struct ReelTopBar: View {
    /// Lets each sheet zoom out of the button that opened it.
    let namespace: Namespace.ID
    /// The pull-to-refresh: the middle dot grows with the pull, and breathes
    /// instead of the wordmark's while a pull refresh runs.
    var pull = PullToRefreshState()
    let open: (FeedSheet) -> Void

    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            // The red dot breathes while feeds refresh, unless the
            // pull-to-refresh dot is already showing it.
            VILLEWordmark(isPulsing: viewModel.isRefreshing && !pull.isRefreshing)

            Spacer()

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    // Identifiers for the store screenshots' UI test, the same in every language.
                    barButton("person.2", label: "People") { open(.members) }
                        .matchedTransitionSource(id: FeedSheet.members, in: namespace)
                        .accessibilityIdentifier("people")
                    barButton("slider.horizontal.3", label: "Settings") { open(.settings) }
                        .matchedTransitionSource(id: FeedSheet.settings, in: namespace)
                        .accessibilityIdentifier("settings")
                }
            }
        }
        .padding(.horizontal, 20)
        .overlay {
            RefreshDot(progress: pull.progress, isRefreshing: pull.isRefreshing)
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
