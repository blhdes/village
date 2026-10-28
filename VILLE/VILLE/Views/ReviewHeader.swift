//
//  ReviewHeader.swift
//  VILLE
//
//  Poster, title, year and the author's rating at the top of a review.
//  Used by both the reel and the full reader. Stars, like and rewatch wear
//  the yellow, red and blue of the Village du Cinéma plates.
//

import SwiftUI

/// Poster, title, year and the author's rating — shared by reel and reader.
struct ReviewHeader: View {
    let review: Review
    /// The poster to show; nil hides it (posters off, or none on TMDB).
    let posterURL: URL?
    /// Flips to the film's next poster; nil when it only has one.
    var onPosterTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let posterURL {
                // A fixed frame, so old and new posters crossfade in place.
                ZStack {
                    poster(posterURL)
                        .id(posterURL)
                        .transition(.opacity)
                }
                .frame(width: 84, height: 126)
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
                            .foregroundStyle(Color.brandYellow)
                    }
                    if review.liked {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.brandRed)
                            .accessibilityLabel("Liked")
                    }
                    if review.isRewatch {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .foregroundStyle(Color.brandBlue)
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

    @ViewBuilder
    private func poster(_ url: URL) -> some View {
        let image = AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color.primary.opacity(0.06)
            }
        }
        .frame(width: 84, height: 126)
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }

        if let onPosterTap {
            image
                .contentShape(.rect(cornerRadius: 6))
                .onTapGesture(perform: onPosterTap)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows another poster for this film")
        } else {
            image
        }
    }

    /// "  2026" in a lighter, smaller style after the title.
    private var yearText: Text {
        guard let year = review.filmYear else { return Text(verbatim: "") }
        return Text(verbatim: "  \(year)")
            .font(.system(.title3, design: .serif))
            .foregroundStyle(Color.primary.opacity(0.55))
    }
}
