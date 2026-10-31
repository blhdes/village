//
//  SpoilerGate.swift
//  VILLE
//
//  The glass shield over a review that may contain spoilers. Tap anywhere
//  on it to reveal: one-way, and kept until the app quits (`ReelSession`).
//  Used on the reel and in the reader, since a review can be bookmarked
//  before it's revealed (to read after watching the film).
//
//  Put it inside a `GlassEffectContainer` that stays while the gate comes
//  and goes, so the glass can dissolve as the review appears.
//

import SwiftUI

struct SpoilerGate: View {
    let reviewID: String

    @Environment(ReelSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// No glass button inside it: glass can't refract other glass, so it
    /// would look muddy. The glass dissolves as the review appears (a plain
    /// fade with Reduce Motion).
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                session.revealSpoilers(for: reviewID)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("This review may contain spoilers.")
                    .font(.system(.body, design: .serif).italic())
                Text("Tap to show it")
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .glassEffectTransition(reduceMotion ? .identity : .materialize)
    }
}
