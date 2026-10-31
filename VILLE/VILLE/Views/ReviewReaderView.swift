//
//  ReviewReaderView.swift
//  VILLE
//
//  The full text of a review. `ReviewReaderView` is the sheet a reel's
//  "Continue reading" opens; `ReviewReader` is the review inside it, also
//  shown one after another on the Bookmarks page (`BookmarksReader`).
//

import SwiftUI

/// The sheet opened from a reel.
struct ReviewReaderView: View {
    let review: Review
    /// The same poster the reel was showing.
    let posterURL: URL?
    /// Settings → Stars and likes, as on the reel.
    var showRating = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ReviewReader(review: review, posterURL: posterURL, showRating: showRating)
            }
            .scrollIndicators(.hidden)
            .background(Color.reelBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationBackground(Color.reelBackground)
    }
}

/// Header, full text and actions, with the page's margins. It doesn't
/// scroll by itself: the sheet above scrolls one review, the Bookmarks
/// page all of them in a row. A review that may contain spoilers stays
/// covered until it's revealed (a bookmark can be made before that, to
/// read after watching the film).
struct ReviewReader: View {
    let review: Review
    let posterURL: URL?
    var showRating = true

    @Environment(ReviewTranslator.self) private var translator
    @Environment(ReelSession.self) private var session

    private var isSpoilerCovered: Bool {
        review.containsSpoilers && !session.revealedSpoilers.contains(review.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ReviewHeader(review: review, posterURL: posterURL, showRating: showRating)
            // The container stays while the gate goes, so its glass can dissolve.
            GlassEffectContainer {
                if isSpoilerCovered {
                    SpoilerGate(reviewID: review.id)
                } else {
                    // Translated if the reel was (or the header's note is tapped here).
                    ReviewTextView(blocks: translator.blocks(for: review))
                }
            }
            if let url = review.url {
                ReviewActions(review: review, url: url)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
