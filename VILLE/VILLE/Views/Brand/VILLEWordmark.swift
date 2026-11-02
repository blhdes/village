//
//  VILLEWordmark.swift
//  VILLE
//
//  VILLE's wordmark: "ville." in Source Serif 4 Italic (weight 670, optical
//  size 33), ending on a big red full stop, the only touch of color. A full
//  stop because the feed has an end, like the "Fin" card. Chosen in the logo
//  study on 2026-11-02 and drawn from the font's own outlines, never by
//  hand (brand/export_marks.py): `WordmarkLetters` in the text color and
//  `WordmarkDot` in brand red, two layers so the dot can breathe on its own
//  while refreshing. Change the logo here and it changes everywhere it's
//  used (top bar, loading screen, Settings → Look).
//

import SwiftUI

struct VILLEWordmark: View {
    /// Point size of the letters, as if the wordmark were text.
    var size: CGFloat = 28
    /// Makes the red dot breathe, e.g. while refreshing.
    var isPulsing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The two layers' shared canvas, in ems: the outlines' tight bounds,
    /// as printed by brand/export_marks.py.
    private static let widthInEms: CGFloat = 1.99913
    private static let heightInEms: CGFloat = 0.74744

    var body: some View {
        ZStack {
            Image(.wordmarkLetters)
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.primary)

            PhaseAnimator(dotOpacities) { opacity in
                Image(.wordmarkDot)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.brandRed)
                    .opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
            // A fresh animator when pulsing starts or stops, so the dot
            // settles back to full color instead of breathing forever.
            .id(isPulsing)
        }
        .frame(width: size * Self.widthInEms, height: size * Self.heightInEms)
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
