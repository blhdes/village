//
//  PosterImage.swift
//  VILLE
//
//  A film poster that crossfades from one to the next. While a poster is
//  on its way (TMDB still looking the film up, or the image downloading) a
//  quiet skeleton breathes in its place; a poster already in memory shows
//  at once, with no skeleton in between. Used by ReviewHeader.
//

import SwiftUI

struct PosterImage: View {
    /// The poster to show; nil while the film's art is still being looked up.
    let url: URL?

    /// The last poster loaded, with the URL it belongs to.
    @State private var loaded: Loaded?
    /// A poster that couldn't be loaded gets a plain tile, not the skeleton.
    @State private var failedURL: URL?

    private struct Loaded {
        let url: URL
        let image: CGImage
    }

    /// What to draw now: this URL's poster if it's loaded or in memory,
    /// otherwise nothing yet (the skeleton).
    private var shown: Loaded? {
        guard let url else { return nil }
        if let loaded, loaded.url == url { return loaded }
        if let image = PosterImageCache.shared.image(for: url) { return Loaded(url: url, image: image) }
        return nil
    }

    var body: some View {
        let shown = self.shown

        ZStack {
            if let shown {
                Image(decorative: shown.image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .id(shown.url)
                    .transition(.opacity)
            } else if let url, url == failedURL {
                Color.primary.opacity(0.06)
            } else {
                LoadingSkeleton()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: shown?.url)
        .animation(.easeInOut(duration: 0.3), value: failedURL)
        .accessibilityHidden(true)
        .task(id: url) {
            guard let url, shown?.url != url else { return }
            if let image = await PosterImageCache.shared.load(url) {
                loaded = Loaded(url: url, image: image)
            } else {
                failedURL = url
            }
        }
    }
}

/// A quiet placeholder that breathes while something loads, at the same
/// slow pace as the loading dot. Holds still with Reduce Motion.
struct LoadingSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PhaseAnimator(reduceMotion ? [0.7] : [0.45, 1]) { strength in
            Rectangle()
                .fill(Color.primary.opacity(0.11))
                .opacity(strength)
        } animation: { _ in
            .easeInOut(duration: 0.9)
        }
    }
}

#Preview {
    PosterImage(url: nil)
        .frame(width: 84, height: 126)
        .clipShape(.rect(cornerRadius: 3))
        .padding()
}
