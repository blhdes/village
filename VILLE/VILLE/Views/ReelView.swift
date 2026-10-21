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

    @State private var spoilersRevealed = false
    @State private var isReading = false
    @State private var contentHeight: CGFloat = 0
    @State private var boxHeight: CGFloat = 0

    private var isOverflowing: Bool { contentHeight > boxHeight + 1 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ReelBackground(url: showBackdrop ? review.backdropURL : nil)

            VStack(alignment: .leading, spacing: 24) {
                ReviewHeader(review: review, showPoster: showPoster)

                if review.containsSpoilers && !spoilersRevealed {
                    spoilerGate
                    Spacer(minLength: 0)
                } else {
                    reviewBody
                }

                actions
            }
            .padding(.horizontal, 24)
            .padding(.top, insets.top + 64)
            .padding(.bottom, insets.bottom + 20)
        }
        .sheet(isPresented: $isReading) {
            ReviewReaderView(review: review, showPoster: showPoster)
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
                }
            }
            .contentShape(.rect)
            .onTapGesture { if isOverflowing { isReading = true } }
    }

    private var spoilerGate: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("This review may contain spoilers", systemImage: "eye.slash")
                .font(.subheadline.weight(.medium))
            Button("Show review") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    spoilersRevealed = true
                }
            }
            .buttonStyle(.glass)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if let url = review.url {
            ReviewActions(review: review, url: url)
        }
    }
}

// MARK: - Header

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
                    Color.white.opacity(0.06)
                }
                .frame(width: 84, height: 126)
                .clipShape(.rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Review by \(Text(review.authorName).bold())")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))

                Text("\(Text(review.filmTitle).font(.system(.title, design: .serif, weight: .bold)))\(yearText)")
                    .lineLimit(3)

                HStack(spacing: 8) {
                    if !review.stars.isEmpty {
                        Text(review.stars)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    if review.liked {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white.opacity(0.7))
                            .accessibilityLabel("Liked")
                    }
                    if review.isRewatch {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .foregroundStyle(.white.opacity(0.6))
                            .accessibilityLabel("Rewatch")
                    }
                }
                .font(.subheadline)

                Text(review.watchedLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 10)
    }

    /// "  2026" in a lighter, smaller style after the title.
    private var yearText: Text {
        guard let year = review.filmYear else { return Text(verbatim: "") }
        return Text(verbatim: "  \(year)")
            .font(.system(.title3, design: .serif))
            .foregroundStyle(.white.opacity(0.55))
    }
}

// MARK: - Actions

/// Share (as a link to the original — never the text itself, per Letterboxd's
/// ToS on exporting others' content) and open the review on Letterboxd.
struct ReviewActions: View {
    let review: Review
    let url: URL

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ShareLink(
                    item: url,
                    subject: Text(review.filmTitle),
                    message: Text("\(review.filmTitle) — review by \(review.authorName)")
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Link(destination: url) {
                    Label("View on Letterboxd", systemImage: "arrow.up.right")
                }

                Spacer(minLength: 0)
            }
            .font(.subheadline.weight(.medium))
            .buttonStyle(.glass)
        }
    }
}

// MARK: - Background

/// TMDB backdrop across the top of the screen, fading into black.
private struct ReelBackground: View {
    let url: URL?

    var body: some View {
        ZStack(alignment: .top) {
            Color.black

            if let url {
                GeometryReader { proxy in
                    AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.62)
                    .clipped()
                    .overlay(Color.black.opacity(0.35))
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
