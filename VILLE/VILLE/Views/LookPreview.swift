//
//  LookPreview.swift
//  VILLE
//
//  The top of Settings: the reel on screen in miniature (its backdrop,
//  header and first lines), drawn with the current look, so each switch
//  below shows what it does the moment it's flipped. On the end card, the
//  newest review with art stands in. Only to look at: nothing in it reacts
//  to taps, and VoiceOver skips it (the switches say it all).
//

import SwiftUI

struct LookPreview: View {
    /// The review to draw, and how the feed showed it.
    struct Sample {
        let review: Review
        /// The backdrop and poster the reel on screen picked.
        let backdropPick: Int
        let posterPick: Int
        /// A spoiler review not revealed yet keeps its words covered here too.
        let isSpoilerCovered: Bool
    }

    let sample: Sample
    let look: ReelLook

    @Environment(ReviewTranslator.self) private var translator

    /// Room for the backdrop above the header, as under a reel's top bar.
    private let headerTop: CGFloat = 52
    /// About two lines of review text, growing with the text size.
    @ScaledMetric(relativeTo: .body) private var excerptHeight: CGFloat = 52

    private let corner: CGFloat = 24

    private var review: Review { sample.review }

    /// The reel's poster: the official one unless Alternative posters is
    /// on. Nil with posters off.
    private var posterURL: URL? {
        guard look.showPoster else { return nil }
        return review.posterURL(pick: look.alternativePosters ? sample.posterPick : 0)
    }

    private var backdropURL: URL? {
        look.showBackdrop ? review.backdropURL(pick: sample.backdropPick) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ReviewHeader(review: review, posterURL: posterURL, showRating: look.showRating)
            excerpt
        }
        .padding(.horizontal, 20)
        .padding(.top, headerTop)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Top-aligned: the backdrop's band is taller than the card, and
        // its fade is measured from the top, as on a reel.
        .background(alignment: .top) {
            ReelBackground(url: backdropURL, headerTop: headerTop)
        }
        .clipShape(.rect(cornerRadius: corner))
        .overlay {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: look)
    }

    /// The first lines of the review, fading out like a reel's text that
    /// goes on. A covered spoiler shows the gate's sentence instead.
    @ViewBuilder
    private var excerpt: some View {
        if sample.isSpoilerCovered {
            Text("This review may contain spoilers.")
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(Color.primary.opacity(0.88))
        } else {
            ReviewTextView(blocks: Array(translator.blocks(for: review).prefix(2)))
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: excerptHeight, alignment: .top)
                .clipped()
                .mask {
                    LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom)
                }
        }
    }
}

extension LookPreview.Sample {
    /// The reel on screen (`pageID` nil means the first one), so the look
    /// switches change it before the reader's eyes. On the end card the
    /// newest review with art stands in, its second poster ready for
    /// Alternative posters. Nil while there's nothing to read.
    static func onScreen(in queue: ReelQueue, pageID: Int?, reviews: [Review], revealedSpoilers: Set<String>) -> Self? {
        func sample(_ review: Review, backdropPick: Int, posterPick: Int) -> Self {
            Self(
                review: review,
                backdropPick: backdropPick,
                posterPick: posterPick,
                isSpoilerCovered: review.containsSpoilers && !revealedSpoilers.contains(review.id)
            )
        }

        let pageID = pageID ?? queue.slots.first?.id
        if let slot = queue.slots.first(where: { $0.id == pageID }),
           let review = reviews.first(where: { $0.id == slot.reviewID }) {
            return sample(review, backdropPick: slot.backdropPick, posterPick: slot.posterPick)
        }

        let byDate: (Review, Review) -> Bool = { $0.publishedAt < $1.publishedAt }
        let withArt = reviews.filter { !$0.containsSpoilers && !$0.posterChoices.isEmpty && !$0.backdropChoices.isEmpty }
        guard let standIn = withArt.max(by: byDate) ?? reviews.max(by: byDate) else { return nil }
        return sample(standIn, backdropPick: 0, posterPick: 1)
    }
}
