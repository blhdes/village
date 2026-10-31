//
//  ReviewTextView.swift
//  VILLE
//
//  Draws the blocks produced by `ReviewHTML`: paragraphs, indented quotes
//  with a side rule, and bulleted or numbered list items. Links take the
//  brand blue and open in Safari inside the app. The text can be selected
//  and copied (sharing stays a link to the original, see `ReviewActions`).
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
        .tint(Color.brandBlue)
        // Long-press to copy. From iOS 27 the handles pick any stretch of a
        // paragraph; on iOS 26 the menu copies the whole paragraph.
        .textSelection(.enabled)
        // Links open in Safari inside the app, so reading continues after.
        .environment(\.openURL, .inAppBrowser)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func row(for block: ReviewBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
        case .quote(let text):
            HStack(spacing: 16) {
                // A hairline, like a printed pull quote's rule.
                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 1)
                Text(text)
                    .italic()
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .fixedSize(horizontal: false, vertical: true)
        case .listItem(let marker, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                // 0.6 keeps list numbers at 4.5:1 or better on white.
                Text(marker)
                    .foregroundStyle(Color.primary.opacity(0.6))
                Text(text)
            }
        }
    }
}

extension OpenURLAction {
    /// Web links open in Safari inside the app; anything else goes to the
    /// system as usual.
    static let inAppBrowser = OpenURLAction { url in
        let isWeb = url.scheme == "https" || url.scheme == "http"
        return .systemAction(url, prefersInApp: isWeb)
    }
}
