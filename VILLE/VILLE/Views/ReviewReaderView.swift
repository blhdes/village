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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ReviewHeader(review: review, posterURL: posterURL, showRating: showRating)
                    ReviewTextView(blocks: ReviewHTML.blocks(for: review))
                        .textSelection(.enabled)
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
