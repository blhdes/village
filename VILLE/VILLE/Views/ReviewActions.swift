//
//  ReviewActions.swift
//  VILLE
//
//  The Share and "View on Letterboxd" buttons under a review. Used by both
//  the reel and the full reader.
//

import SwiftUI

/// Share (as a link to the original — never the text itself, per Letterboxd's
/// ToS on exporting others' content) and open the review on Letterboxd.
struct ReviewActions: View {
    let review: Review
    let url: URL

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            // With large text sizes, Share drops its title first, so
            // "View on Letterboxd" (the credit) keeps its words.
            ViewThatFits(in: .horizontal) {
                buttons(shareTitle: true)
                buttons(shareTitle: false)
            }
            .font(.system(.subheadline, design: .serif, weight: .medium))
            .buttonStyle(.glass)
        }
    }

    private func buttons(shareTitle: Bool) -> some View {
        HStack(spacing: 10) {
            ShareLink(
                item: url,
                subject: Text(review.filmTitle),
                message: Text("\(review.filmTitle) · review by \(review.authorName)")
            ) {
                if shareTitle {
                    Label("Share", systemImage: "square.and.arrow.up")
                } else {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
            }

            // Official dots badge from Letterboxd's Brand page — allowed
            // here because the button links to letterboxd.com.
            Link(destination: url) {
                Label {
                    Text("View on Letterboxd")
                } icon: {
                    Image(.letterboxdDots)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
