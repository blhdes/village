//
//  ReelView.swift
//  VILLE
//
//  One full-screen review, laid out like a Letterboxd review page: film
//  header, "Review by", rating, then the text (`ReelTextBox`: long reviews
//  fade out and open the full reader). Every reel credits the author and
//  links back to the original on Letterboxd.
//
//  The backdrop (and, with Alternative posters on, the poster) is picked
//  per appearance by the slot, so a film looks different each time it
//  comes round. Tapping the poster flips to the film's next one.
//

import SwiftUI

/// The Settings → Look choices a reel needs.
struct ReelLook: Equatable {
    var showPoster: Bool
    var showBackdrop: Bool
    var alternativePosters: Bool
    var showRating: Bool
}

struct ReelView: View {
    let review: Review
    let slot: ReelSlot
    let look: ReelLook
    let insets: EdgeInsets

    @Environment(ReelSession.self) private var session
    @Environment(FeedViewModel.self) private var viewModel

    /// Lets the reader sheet zoom out of the "Continue reading" button.
    @Namespace private var readerNamespace

    @State private var isReading = false
    /// How many times the poster was tapped, each showing the next one.
    @State private var posterTaps = 0

    /// Where the header starts, below the top bar. The backdrop's fade is
    /// measured from here, so it always clears the text.
    private var headerTop: CGFloat { insets.top + 64 }

    private var isSpoilerCovered: Bool {
        review.containsSpoilers && !session.revealedSpoilers.contains(review.id)
    }

    /// Official poster unless Alternative posters is on, then a random one.
    private var posterURL: URL? {
        guard look.showPoster else { return nil }
        let first = look.alternativePosters ? slot.posterPick : 0
        return review.posterURL(pick: first + posterTaps)
    }

    /// Tapping the poster flips to the next one, if the film has more.
    private var posterTap: (() -> Void)? {
        guard review.posterChoices.count > 1 else { return nil }
        return { showNextPoster() }
    }

    /// The poster the next tap will show, fetched ahead so the flip is instant.
    private var nextPosterURL: URL? {
        guard posterTap != nil, look.showPoster else { return nil }
        let first = look.alternativePosters ? slot.posterPick : 0
        return review.posterURL(pick: first + posterTaps + 1)
    }

    /// TMDB hasn't answered for this film yet (a member was just added, or
    /// new reviews came in): the poster's place shows a skeleton meanwhile.
    private var isPosterPending: Bool {
        look.showPoster && review.needsArt && viewModel.isLoadingArt
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ReelBackground(
                url: look.showBackdrop ? review.backdropURL(pick: slot.backdropPick) : nil,
                headerTop: headerTop
            )

            VStack(alignment: .leading, spacing: 24) {
                ReviewHeader(
                    review: review,
                    posterURL: posterURL,
                    isPosterPending: isPosterPending,
                    showRating: look.showRating,
                    onPosterTap: posterTap
                )

                // The container stays put while the `if` swaps its content,
                // so the spoiler glass can dissolve instead of just vanishing.
                GlassEffectContainer {
                    if isSpoilerCovered {
                        SpoilerGate(reviewID: review.id)
                            .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        ReelTextBox(review: review, readerNamespace: readerNamespace) {
                            isReading = true
                        }
                    }
                }

                actions
            }
            .padding(.horizontal, 24)
            .padding(.top, headerTop)
            .padding(.bottom, insets.bottom + 20)
        }
        .sheet(isPresented: $isReading) {
            ReviewReaderView(review: review, posterURL: posterURL, showRating: look.showRating)
                .navigationTransition(.zoom(sourceID: review.id, in: readerNamespace))
        }
        .sensoryFeedback(.selection, trigger: posterTaps)
        .onChange(of: nextPosterURL, initial: true) { _, url in
            PosterImageCache.shared.prefetch(url)
        }
    }

    private func showNextPoster() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            posterTaps += 1
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if let url = review.url {
            ReviewActions(review: review, url: url)
        }
    }
}
