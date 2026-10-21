//
//  ReviewHeader.swift
//  VILLE
//
//  Poster, title, year and the author's rating at the top of a review.
//  Used by both the reel and the full reader.
//

import SwiftUI

/// Poster, title, year and the author's rating — shared by reel and reader.
struct ReviewHeader: View {
    let review: Review
    let showPoster: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if showPoster, let posterURL = review.posterURL {
                AsyncImage(url: posterURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.primary.opacity(0.06)
                }
                .frame(width: 84, height: 126)
                .clipShape(.rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Review by \(Text(review.authorName).bold())")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.65))

                Text("\(Text(review.filmTitle).font(.system(.title, design: .serif, weight: .bold)))\(yearText)")
                    .lineLimit(3)

                HStack(spacing: 8) {
                    if !review.stars.isEmpty {
                        Text(review.stars)
                            .foregroundStyle(Color.primary.opacity(0.9))
                    }
                    if review.liked {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.primary.opacity(0.7))
                            .accessibilityLabel("Liked")
                    }
                    if review.isRewatch {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .accessibilityLabel("Rewatch")
                    }
                }
                .font(.subheadline)

                Text(review.watchedLabel)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.5))
            }
        }
        .shadow(color: Color.reelBackground.opacity(0.4), radius: 10)
    }

    /// "  2026" in a lighter, smaller style after the title.
    private var yearText: Text {
        guard let year = review.filmYear else { return Text(verbatim: "") }
        return Text(verbatim: "  \(year)")
            .font(.system(.title3, design: .serif))
            .foregroundStyle(Color.primary.opacity(0.55))
    }
}
