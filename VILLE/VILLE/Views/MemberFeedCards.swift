//
//  MemberFeedCards.swift
//  VILLE
//
//  The pages of a member's feed that aren't reviews (`MemberFeedView`):
//  their name while their reviews arrive, its full stop breathing like the
//  wordmark's; and a card with a headline, a line of text, Follow and
//  Close, for the end of their feed, a feed with nothing to read, or one
//  that couldn't load.
//

import SwiftUI

/// A headline, a line of serif text and the buttons, on the plain page.
struct MemberFeedCard: View {
    let headline: EditorialHeadline
    let message: Text
    /// Says what went wrong, in red.
    var isError = false
    /// Nil leaves Follow out: followed already, or the feed didn't load.
    let onFollow: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            headline
                .multilineTextAlignment(.center)

            message
                .font(.system(.body, design: .serif))
                .foregroundStyle(isError ? Color.brandRed : Color.primary.opacity(0.65))
                .multilineTextAlignment(.center)

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    if let onFollow {
                        Button("Follow", action: onFollow)
                            .buttonStyle(.glassProminent)
                    }
                    Button("Close", action: onClose)
                        .buttonStyle(.glass)
                }
            }
            .font(.system(.subheadline, design: .serif, weight: .medium))
            .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelBackground)
    }
}

/// Their name while their reviews arrive, its full stop breathing like the
/// wordmark's while the feed refreshes.
struct MemberFeedLoading: View {
    let name: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // A full stop the name already ends on becomes the red one.
                Text(name.hasSuffix(".") ? String(name.dropLast()) : name)
                PhaseAnimator(reduceMotion ? [1.0] : [1.0, 0.2]) { opacity in
                    Text(verbatim: ".")
                        .foregroundStyle(Color.brandRed)
                        .opacity(opacity)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }
            }
            .font(.system(.title, design: .serif).italic())
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Text("Fetching reviews…")
                .datelineStyle()
                .foregroundStyle(Color.primary.opacity(0.6))
        }
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
    }
}
