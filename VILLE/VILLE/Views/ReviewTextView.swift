//
//  ReviewTextView.swift
//  VILLE
//
//  Draws the blocks produced by `ReviewHTML`: paragraphs, indented quotes
//  with a side rule, and bulleted or numbered list items.
//

import SwiftUI

struct ReviewTextView: View {
    let blocks: [ReviewBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                row(for: block)
            }
        }
        .font(.system(.body, design: .serif))
        .foregroundStyle(Color.primary.opacity(0.88))
        .lineSpacing(5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func row(for block: ReviewBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
        case .quote(let text):
            HStack(spacing: 14) {
                Capsule()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 2)
                Text(text)
                    .italic()
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .fixedSize(horizontal: false, vertical: true)
        case .listItem(let marker, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(marker)
                    .foregroundStyle(Color.primary.opacity(0.5))
                Text(text)
            }
        }
    }
}
