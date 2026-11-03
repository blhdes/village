//
//  ReviewHeader.swift
//  VILLE
//
//  Poster, byline, title, year and the author's rating at the top of a
//  review, set like a magazine header: a serif byline, a serif headline and
//  a dateline in spaced capitals. Used by both the reel and the full reader.
//  Stars, like and rewatch are set like type, in the text color: symbols on
//  the serif line's baseline, the font's own "½", middle dots between them,
//  as a printed film guide would. Hideable in Settings → Stars and likes.
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
    /// What tapping "Review by …" offers (`ReviewByline`): on a reel, the
    /// author's menu; elsewhere nothing.
    var byline: BylineMenu = .none

    @Environment(\.openURL) private var openURL

    /// Corners of a printed photo: barely rounded.
    private let posterCorner: CGFloat = 3

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if posterURL != nil || isPosterPending {
                poster
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }

            VStack(alignment: .leading, spacing: 8) {
                ReviewByline(review: review, menu: byline)

                title

                if showRating && hasRatingMarks {
                    ratingRow
                }

                // "Rewatched" stays here even with the rating hidden.
                Text(review.watchedLabel)
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.75))

                // "Translate", only when the review isn't in the reader's
                // language.
                TranslationNote(review: review)
            }
            // No halos: on a reel the backdrop fades out before the rating,
            // so the text sits straight on the page (see ReelBackground).
        }
    }

    /// Title and year. Tapping it searches the web for the film in Safari
    /// inside the app, as the mobile app does.
    @ViewBuilder
    private var title: some View {
        let text = Text("\(Text(review.filmTitle).font(.system(.title, design: .serif, weight: .bold)))\(yearText)")
            .lineLimit(3)

        if let searchURL = review.filmSearchURL {
            Button {
                openURL(searchURL, prefersInApp: true)
            } label: {
                text.multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Searches the web for this film")
        } else {
            text
        }
    }

    private var hasRatingMarks: Bool {
        review.starRating != nil || review.liked || review.isRewatch
    }

    /// "★★★½ · ♥ · ↻" set as one serif line in the text color. The symbols
    /// sit on the baseline at a small scale, so they read as type, not icons.
    private var ratingRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            if let stars = review.starRating {
                starMarks(full: stars.full, half: stars.half)
            }
            if review.liked {
                if review.starRating != nil { separator }
                Image(systemName: "heart.fill")
                    .accessibilityLabel("Liked")
            }
            if review.isRewatch {
                if review.starRating != nil || review.liked { separator }
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .accessibilityLabel("Rewatch")
            }
        }
        .font(.system(.subheadline, design: .serif))
        .imageScale(.small)
    }

    /// Whole stars set close like letters, then the serif's own "½".
    private func starMarks(full: Int, half: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1.5) {
            ForEach(0..<full, id: \.self) { _ in
                Image(systemName: "star.fill")
            }
            if half {
                Text(verbatim: "½")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(Double(full) + (half ? 0.5 : 0), format: .number) stars"))
    }

    /// The middle dot between marks, quieter than the marks themselves.
    private var separator: some View {
        Text(verbatim: "·")
            .foregroundStyle(Color.primary.opacity(0.6))
            .accessibilityHidden(true)
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
