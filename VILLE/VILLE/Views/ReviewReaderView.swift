//
//  ReviewReaderView.swift
//  VILLE
//
//  The full text of a long review, opened from a reel's "Continue reading".
//

import SwiftUI

struct ReviewReaderView: View {
    let review: Review
    /// The same poster the reel was showing.
    let posterURL: URL?
    /// Settings → Stars and likes, as on the reel.
    var showRating = true

    @Environment(\.dismiss) private var dismiss
    @Environment(ReviewTranslator.self) private var translator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ReviewHeader(review: review, posterURL: posterURL, showRating: showRating)
                    // Translated if the reel was (or the header's note is tapped here).
                    ReviewTextView(blocks: translator.blocks(for: review))
                    if let url = review.url {
                        ReviewActions(review: review, url: url)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationBackground(Color.reelBackground)
    }
}
