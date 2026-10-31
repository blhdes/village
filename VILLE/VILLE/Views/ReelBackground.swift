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
/// Sharp behind the top bar, then it softens (a growing blur) and fades out
/// across the header, so the text sits on the page with no outlines or glows.
/// The fade is measured in points from the header's top, so it lands on the
/// same lines on every iPhone. Set for legibility: even on a white frame in
/// dark mode (or a black one in light mode), "Review by" keeps 4.5:1 and the
/// stars, like and rewatch 3:1, because the image is all but gone by the
/// rating row.
struct ReelBackground: View {
    let url: URL?
    /// Where the review header starts, from the top of the screen.
    let headerTop: CGFloat

    /// A point of a fade: distance from the header's top, and how much shows there.
    private typealias FadePoint = (offset: CGFloat, opacity: Double)

    /// How strongly the image shows, from just above the header to past the rating.
    private static let fade: [FadePoint] = [
        (-60, 1), (-20, 0.92), (8, 0.52), (74, 0.1), (110, 0.03), (160, 0),
    ]
    /// The blurred copy fades in over this range, so the image softens as it goes.
    private static let blurRamp: [FadePoint] = [(-50, 0), (20, 1)]

    /// The image band ends where the fade does.
    private var height: CGFloat { headerTop + (Self.fade.last?.offset ?? 0) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.reelBackground

            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                    if let image = phase.image {
                        ZStack {
                            filled(image)
                            filled(image)
                                .blur(radius: 20, opaque: true)
                                .mask { gradient(Self.blurRamp) }
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
