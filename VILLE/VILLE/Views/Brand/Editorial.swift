//
//  Editorial.swift
//  VILLE
//
//  The small typographic pieces that give VILLE its printed, editorial
//  feel, echoing the "ville." wordmark: serif italic headlines ending on a
//  red full stop, datelines in spaced capitals, and sheet titles in serif
//  italic.
//

import SwiftUI

/// A serif italic headline ending on the wordmark's red full stop.
/// For the big moments only (empty states), so the dot keeps its meaning.
struct EditorialHeadline: View {
    let text: LocalizedStringKey
    var font: Font = .system(.title, design: .serif)

    var body: some View {
        Text("\(Text(text))\(Text(verbatim: ".").foregroundStyle(Color.brandRed))")
            .font(font.italic())
    }
}

extension View {
    /// Meta lines (dates, small notes) in spaced capitals, like a
    /// magazine's dateline.
    func datelineStyle() -> some View {
        font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .tracking(1.1)
    }

    /// A sheet's inline title in serif italic, like the wordmark. The plain
    /// navigation title stays underneath for VoiceOver and the app switcher.
    func editorialTitle(_ title: LocalizedStringKey) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(.headline, design: .serif).italic())
                }
                .sharedBackgroundVisibility(.hidden)
            }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        EditorialHeadline(text: "Reviews, one at a time")
        Text(verbatim: "Watched Oct 14, 2026")
            .datelineStyle()
            .foregroundStyle(Color.primary.opacity(0.65))
    }
    .padding()
}
