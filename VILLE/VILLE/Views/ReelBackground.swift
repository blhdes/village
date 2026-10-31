//
//  ReelBackground.swift
//  VILLE
//
//  The TMDB backdrop behind each reel, and how it fades so the header
//  text stays readable without halos.
//

import SwiftUI

/// TMDB backdrop at the top of the screen, dissolving into the background.
/// A different one of the film's backdrops each time it appears.
///
/// The whole frame shows edge to edge (nothing cropped off the sides),
/// sharp behind the top bar. Across the header it melts into a blurred copy
/// of itself, which carries the film's colors down to the first lines of
/// the review before fading out. The fade is measured in points from the
/// header's top, so it lands on the same lines on every iPhone. Set for
/// legibility: even on a white frame in dark mode (or a black one in light
/// mode), every header line keeps 4.5:1 (3:1 for the title and the marks),
/// because the image never shows above 68% where the text starts.
struct ReelBackground: View {
    let url: URL?
    /// Where the review header starts, from the top of the screen.
    let headerTop: CGFloat

    /// A point of a fade: distance from the header's top, and how much shows there.
    private typealias FadePoint = (offset: CGFloat, opacity: Double)

    /// How strongly the image shows, from the top bar to the first lines of the review.
    private static let fade: [FadePoint] = [
        (-60, 1), (-20, 0.9), (0, 0.68), (60, 0.55), (120, 0.36), (180, 0.18), (250, 0.06), (310, 0),
    ]
    /// How much the sharp frame shows over its blurred copy: crisp behind
    /// the top bar, soft by the title.
    private static let sharpness: [FadePoint] = [(-40, 1), (30, 0)]

    /// The image band ends where the fade does.
    private var height: CGFloat { headerTop + (Self.fade.last?.offset ?? 0) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.reelBackground

            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                    if let image = phase.image {
                        ZStack(alignment: .top) {
                            // The frame's colors, stretched down the band.
                            filled(image)
                                .blur(radius: 30, opaque: true)
                            wholeFrame(image)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .mask { gradient(Self.sharpness) }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .overlay(Color.reelBackground.opacity(0.45))
                .mask { gradient(Self.fade) }
            }
        }
        .ignoresSafeArea()
    }

    /// The image filling the band, cropped to it.
    private func filled(_ image: Image) -> some View {
        Color.clear
            .overlay { image.resizable().scaledToFill() }
            .clipped()
    }

    /// The whole frame across the screen's width, at TMDB's 16:9 backdrop
    /// shape. Even on the smallest iPhone it reaches past the end of
    /// `sharpness`, so its bottom edge never shows.
    private func wholeFrame(_ image: Image) -> some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay { image.resizable().scaledToFill() }
            .clipped()
    }

    /// A top-to-bottom mask through the given points of the band.
    private func gradient(_ points: [FadePoint]) -> LinearGradient {
        LinearGradient(
            stops: points.map { point in
                Gradient.Stop(
                    color: .black.opacity(point.opacity),
                    location: min(max((headerTop + point.offset) / height, 0), 1)
                )
            },
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
