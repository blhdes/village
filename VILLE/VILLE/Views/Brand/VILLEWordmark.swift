//
//  VILLEWordmark.swift
//  VILLE
//
//  VILLE's wordmark: heavy serif capitals whose V carries the yellow, blue
//  and red plates of the Village du Cinéma icon. Change the logo here and
//  it changes everywhere it's used (top bar, loading screen).
//

import SwiftUI

struct VILLEWordmark: View {
    /// Point size of the letters.
    var size: CGFloat = 24
    /// Moves the V's plates in and out of register, e.g. while refreshing.
    var isPulsing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: tracking) {
            PhaseAnimator(plateSpreads) { spread in
                OffsetPrint(step: size * 0.065 * spread) {
                    letters("V")
                }
            } animation: { _ in
                .easeInOut(duration: 0.7)
            }
            // A fresh animator when pulsing starts or stops, so the plates
            // settle back into place instead of breathing forever.
            .id(isPulsing)

            letters("ILLE")
                .tracking(tracking)
                .foregroundStyle(Color.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "VILLE"))
    }

    /// How far the plates sit from the V, as a share of the full offset.
    private var plateSpreads: [CGFloat] {
        isPulsing && !reduceMotion ? [1, 0.2] : [1]
    }

    /// Slightly tight letter spacing, scaled with the size.
    private var tracking: CGFloat { -size * 0.016 }

    private func letters(_ text: String) -> Text {
        Text(verbatim: text)
            .font(.system(size: size, weight: .black, design: .serif))
    }
}

#Preview {
    VStack(spacing: 32) {
        VILLEWordmark()
        VILLEWordmark(size: 44, isPulsing: true)
    }
}
