//
//  VILLEWordmark.swift
//  VILLE
//
//  VILLE's wordmark: "ville." in a light serif italic, ending on a red full
//  stop, the only touch of color. A full stop because the feed has an end,
//  like the "Fin" card. Change the logo here and it changes everywhere it's
//  used (top bar, loading screen).
//

import SwiftUI

struct VILLEWordmark: View {
    /// Point size of the letters.
    var size: CGFloat = 28
    /// Makes the red dot breathe, e.g. while refreshing.
    var isPulsing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: "ville")
                .foregroundStyle(Color.primary)

            PhaseAnimator(dotOpacities) { opacity in
                Text(verbatim: ".")
                    .foregroundStyle(Color.brandRed)
                    .opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
            // A fresh animator when pulsing starts or stops, so the dot
            // settles back to full color instead of breathing forever.
            .id(isPulsing)
        }
        .font(.system(size: size, weight: .regular, design: .serif).italic())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "VILLE"))
    }

    /// The dot's opacity steps: it fades in and out only while pulsing.
    private var dotOpacities: [Double] {
        isPulsing && !reduceMotion ? [1, 0.2] : [1]
    }
}

#Preview {
    VStack(spacing: 32) {
        VILLEWordmark()
        VILLEWordmark(size: 44, isPulsing: true)
    }
}
