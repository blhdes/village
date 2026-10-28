//
//  ReviewReaderView.swift
//  VILLE
//
//  The full text of a long review, opened from a reel's "Read more".
//

import SwiftUI

struct ReviewReaderView: View {
    let review: Review
    let showPoster: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ReviewHeader(review: review, showPoster: showPoster)
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
