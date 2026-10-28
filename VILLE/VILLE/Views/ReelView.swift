//
//  ReelView.swift
//  VILLE
//
//  One full-screen review, laid out like a Letterboxd review page: film
//  header, "Review by", rating, then the text. Long reviews fade out and
//  open the full reader. Every reel credits the author and links back to
//  the original on Letterboxd.
//

import SwiftUI

struct ReelView: View {
    let review: Review
    let showPoster: Bool
    let showBackdrop: Bool
    let insets: EdgeInsets

    @Environment(FeedViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Lets the reader sheet zoom out of the "Read more" button.
    @Namespace private var readerNamespace

    @State private var isReading = false
    @State private var contentHeight: CGFloat = 0
    @State private var boxHeight: CGFloat = 0

    private var isOverflowing: Bool { contentHeight > boxHeight + 1 }

    private var isSpoilerCovered: Bool {
        review.containsSpoilers && !viewModel.revealedSpoilers.contains(review.id)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ReelBackground(url: showBackdrop ? review.backdropURL : nil)

            VStack(alignment: .leading, spacing: 24) {
                ReviewHeader(review: review, showPoster: showPoster)

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
            .padding(.top, insets.top + 64)
            .padding(.bottom, insets.bottom + 20)
        }
        .sheet(isPresented: $isReading) {
            ReviewReaderView(review: review, showPoster: showPoster)
                .navigationTransition(.zoom(sourceID: review.id, in: readerNamespace))
        }
    }

    // MARK: Body

    /// The text fills the space between header and actions. If it's taller
    /// than that space, it fades out and a "Read more" button appears.
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
                    Button("Read more") { isReading = true }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glass)
                        .matchedTransitionSource(id: review.id, in: readerNamespace)
                }
            }
            .contentShape(.rect)
            .onTapGesture { if isOverflowing { isReading = true } }
    }

    /// One glass shield — tap anywhere on it to reveal. No glass button
    /// inside it: glass can't refract other glass, so it would look muddy.
    /// The glass dissolves as the review appears (a plain fade with Reduce Motion).
    private var spoilerGate: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.revealSpoilers(for: review.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Label("This review may contain spoilers", systemImage: "eye.slash")
                    .font(.subheadline.weight(.medium))
                Text("Show review")
                    .font(.subheadline.weight(.semibold))
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

// MARK: - Background

/// TMDB backdrop across the top of the screen, fading into the background.
private struct ReelBackground: View {
    let url: URL?

    var body: some View {
        ZStack(alignment: .top) {
            Color.reelBackground

            if let url {
                GeometryReader { proxy in
                    AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.62)
                    .clipped()
                    .overlay(Color.reelBackground.opacity(0.35))
                    .mask {
                        LinearGradient(
                            colors: [.black, .black.opacity(0.85), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
