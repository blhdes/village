//
//  ReviewHeader.swift
//  VILLE
//
//  Poster, byline, title, year and the author's rating at the top of a
//  review, set like a magazine header: a serif byline, a serif headline and
//  a dateline in spaced capitals. Used by both the reel and the full reader.
//  Stars, like and rewatch wear the yellow, red and blue of the Village du
//  Cinéma plates (the stars in `starYellow`, deepened in light mode so they
//  read on white), and can be hidden in Settings → Stars and likes.
//

import SwiftUI

/// Poster, byline, title, rating and date — shared by reel and reader.
struct ReviewHeader: View {
    let review: Review
    /// The poster to show; nil hides it (posters off, or none on TMDB).
    let posterURL: URL?
    /// TMDB is still looking the film up: a skeleton holds the poster's
    /// place, so the text doesn't jump sideways when the poster arrives.
    var isPosterPending = false
    /// Shows the stars, like and rewatch marks (Settings → Stars and likes).
    var showRating = true
    /// Flips to the film's next poster; nil when it only has one.
    var onPosterTap: (() -> Void)? = nil

    /// Corners of a printed photo: barely rounded.
    private let posterCorner: CGFloat = 3

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if posterURL != nil || isPosterPending {
                poster
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }

            VStack(alignment: .leading, spacing: 8) {
                byline

                Text("\(Text(review.filmTitle).font(.system(.title, design: .serif, weight: .bold)))\(yearText)")
                    .lineLimit(3)

                if showRating && hasRatingMarks {
                    ratingRow
                }

                // "Rewatched" stays here even with the rating hidden.
                Text(review.watchedLabel)
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            // No halos: on a reel the backdrop fades out before the rating,
            // so the text sits straight on the page (see ReelBackground).
        }
    }

    /// "Review by" in italic, the author upright, both serif.
    private var byline: some View {
        Text("\(Text("Review by").italic().foregroundStyle(Color.primary.opacity(0.7))) \(Text(review.authorName).fontWeight(.semibold))")
            .font(.system(.subheadline, design: .serif))
    }

    private var hasRatingMarks: Bool {
        !review.stars.isEmpty || review.liked || review.isRewatch
    }

    private var ratingRow: some View {
        HStack(spacing: 8) {
            if !review.stars.isEmpty {
                Text(review.stars)
                    .foregroundStyle(Color.starYellow)
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
    }

    /// A fixed frame, so old and new posters (and the skeleton) crossfade in place.
    @ViewBuilder
    private var poster: some View {
        let image = PosterImage(url: posterURL)
            .frame(width: 84, height: 126)
        .clipShape(.rect(cornerRadius: posterCorner))
        .overlay {
            RoundedRectangle(cornerRadius: posterCorner).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }

        if let onPosterTap {
            image
                .contentShape(.rect(cornerRadius: posterCorner))
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
            .foregroundStyle(Color.primary.opacity(0.65))
    }
}
