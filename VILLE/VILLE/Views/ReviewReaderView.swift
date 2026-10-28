//
//  ReviewReaderView.swift
//  VILLE
//
//  The full text of a long review, opened from a reel's "Read more".
//

import SwiftUI

struct ReviewReaderView: View {
    let review: Review
    /// The same poster the reel was showing.
    let posterURL: URL?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ReviewHeader(review: review, posterURL: posterURL)
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
