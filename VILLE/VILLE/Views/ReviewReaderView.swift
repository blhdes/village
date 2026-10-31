//
//  ReviewReaderView.swift
//  VILLE
//
//  The full text of a review. `ReviewReaderView` is the sheet a reel's
//  "Continue reading" opens; `ReviewReader` is the page inside it, also
//  opened from People → Bookmarks.
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
            ReviewReader(review: review, posterURL: posterURL, showRating: showRating)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) { dismiss() }
                    }
                }
        }
        .presentationBackground(Color.reelBackground)
    }
}

/// Header, full text and actions, scrolling. A review that may contain
/// spoilers stays covered until it's revealed (a bookmark can be made
/// before that, to read after watching the film).
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
        ScrollView {
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
        .scrollIndicators(.hidden)
        .background(Color.reelBackground)
    }
}
