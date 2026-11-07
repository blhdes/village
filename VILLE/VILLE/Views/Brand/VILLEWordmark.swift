//
//  VILLEWordmark.swift
//  VILLE
//
//  VILLE's wordmark: "ville." in Source Serif 4 Italic (weight 670, optical
//  size 33), ending on a big red full stop, the only touch of color. A full
//  stop because the feed has an end, like the "Fin" card. Chosen in the logo
//  study on 2026-11-02 and drawn from the font's own outlines, never by
//  hand (brand/export_marks.py): `WordmarkLetters` in the text color and
//  `WordmarkDot` in brand red, two layers so the dot can step aside on its
//  own. It never breathes: breathing belongs to the loading dot
//  (`RefreshDot`), and while that one shows, this one fades out, as if it
//  had gone there. Change the logo here and it changes everywhere it's
//  used (the top bar).
//

import SwiftUI

struct VILLEWordmark: View {
    /// Point size of the letters, as if the wordmark were text.
    var size: CGFloat = 28
    /// False while the loading dot breathes elsewhere on screen: the red
    /// dot fades out, and back in once the reviews are in.
    var showsDot = true

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

            Image(.wordmarkDot)
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.brandRed)
                .opacity(showsDot ? 1 : 0)
                // Slow and soft, so it reads as leaving, not blinking.
                .animation(.easeInOut(duration: 0.6), value: showsDot)
        }
        .frame(width: size * Self.widthInEms, height: size * Self.heightInEms)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "VILLE"))
    }
}

#Preview {
    VStack(spacing: 32) {
        VILLEWordmark()
        VILLEWordmark(size: 44, showsDot: false)
    }
}
