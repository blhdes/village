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
/// For the big moments only (empty states, the end of a member's feed),
/// so the dot keeps its meaning.
struct EditorialHeadline: View {
    private let text: Text
    private let font: Font

    init(text: LocalizedStringKey, font: Font = .system(.title, design: .serif)) {
        self.text = Text(text)
        self.font = font
    }

    /// A name, never translated. A full stop it already ends on ("Dave V.")
    /// becomes the red one.
    init(verbatim name: String, font: Font = .system(.title, design: .serif)) {
        let trimmed = name.hasSuffix(".") ? String(name.dropLast()) : name
        self.text = Text(verbatim: trimmed)
        self.font = font
    }

    var body: some View {
        Text("\(text)\(Text(verbatim: ".").foregroundStyle(Color.brandRed))")
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
