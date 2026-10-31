//
//  ReelView.swift
//  VILLE
//
//  One full-screen review, laid out like a Letterboxd review page: film
//  header, "Review by", rating, then the text. Long reviews fade out and
//  open the full reader. Every reel credits the author and links back to
//  the original on Letterboxd.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Lets the reader sheet zoom out of the "Continue reading" button.
    @Namespace private var readerNamespace

    @State private var isReading = false
    @State private var contentHeight: CGFloat = 0
    @State private var boxHeight: CGFloat = 0
    /// How many times the poster was tapped, each showing the next one.
    @State private var posterTaps = 0

    private var isOverflowing: Bool { contentHeight > boxHeight + 1 }

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
                        spoilerGate
                            .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        reviewBody
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

    // MARK: Body

    /// The text fills the space between header and actions. If it's taller
    /// than that space, it fades out and a "Continue reading" button appears.
    private var reviewBody: some View {
        ReviewTextView(blocks: ReviewHTML.blocks(for: review))
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            // minHeight: 0 lets the box stay smaller than the text, so long
            // reviews get clipped instead of pushing the buttons off screen.
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { boxHeight = $0 }
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: isOverflowing ? 0.75 : 1),
                        .init(color: isOverflowing ? .clear : .black, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                if isOverflowing {
                    Button("Continue reading") { isReading = true }
                        .font(.system(.subheadline, design: .serif, weight: .medium).italic())
                        .buttonStyle(.glass)
                        .matchedTransitionSource(id: review.id, in: readerNamespace)
                }
            }
            .contentShape(.rect)
            // Tapping a cut-off review opens the reader. Only switched on
            // when the text is cut off, so links in a short review keep
            // their own tap (the reader has them all).
            .gesture(
                TapGesture().onEnded { isReading = true },
                including: isOverflowing ? .all : .subviews
            )
    }

    /// One glass shield — tap anywhere on it to reveal. No glass button
    /// inside it: glass can't refract other glass, so it would look muddy.
    /// The glass dissolves as the review appears (a plain fade with Reduce Motion).
    private var spoilerGate: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                session.revealSpoilers(for: review.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("This review may contain spoilers.")
                    .font(.system(.body, design: .serif).italic())
                Text("Tap to show it")
                    .datelineStyle()
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .glassEffectTransition(reduceMotion ? .identity : .materialize)
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if let url = review.url {
            ReviewActions(review: review, url: url)
        }
    }
}
