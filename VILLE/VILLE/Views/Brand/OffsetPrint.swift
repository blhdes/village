//
//  OffsetPrint.swift
//  VILLE
//
//  The Village du Cinéma print look: the content in the primary color, with
//  yellow, blue and red copies peeking out behind it, like print plates
//  slightly out of register. Kept for the "Fin" card only, VILLE's one nod
//  to its sibling apps.
//

import SwiftUI

struct OffsetPrint<Content: View>: View {
    /// Distance between one plate and the next, in points.
    var step: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            // Back to front: red is the furthest plate, yellow the nearest.
            plate(Color.brandRed, depth: 3)
            plate(Color.brandBlue, depth: 2)
            plate(Color.brandYellow, depth: 1)
            content
                .foregroundStyle(Color.primary)
        }
    }

    private func plate(_ color: Color, depth: CGFloat) -> some View {
        content
            .foregroundStyle(color)
            .offset(x: step * depth, y: step * depth)
            .accessibilityHidden(true)
    }
}

#Preview {
    OffsetPrint(step: 2.4) {
        Text(verbatim: "Fin")
            .font(.system(size: 96, weight: .bold, design: .serif))
            .italic()
    }
}
