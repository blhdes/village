//
//  ReviewCard.swift
//  VILLE
//
//  Large, cinematic card that represents a single review in the feed.
//  Inspired by `components/ReviewCard.tsx` from the RN project but reimagined
//  with Liquid Glass: instead of a flat background, the card sits on a
//  translucent glass material with subtle inner glow and vibrancy.
//

import SwiftUI

struct ReviewCard: View {
    let review: Review

    /// Max visible characters in the preview — mirrors `MAX_PREVIEW_LENGTH`
    /// from the RN ReviewCard. Past this, we truncate with an ellipsis.
    private let maxPreviewChars = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !review.reviewHTML.isEmpty {
                preview
            }
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Liquid Glass backdrop.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    // Subtle inner border — adds definition on pure-black bg.
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                }
        }
        // Soft depth — keeps cards floating over the cinematic gradient.
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        .sensoryFeedback(.selection, trigger: review.id) // Haptic on tap bubbled up from NavigationLink.
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: Header — movie title + meta

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(review.movieTitle)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Text(review.creator.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.55))

                Text("·")
                    .foregroundStyle(.white.opacity(0.3))

                Text(review.displayDate)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))

                if !review.rating.isEmpty {
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(review.rating)
                        .font(.caption)
                        .foregroundStyle(.yellow.opacity(0.85))
                }

                Spacer()
            }
        }
    }

    // MARK: Preview body

    private var preview: some View {
        Text(truncatedPreview)
            .font(.body)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Plain-text preview of the review, truncated to `maxPreviewChars`.
    /// HTML is rendered in the detail view — the card stays clean.
    private var truncatedPreview: String {
        let plain = review.plainTextPreview
        guard plain.count > maxPreviewChars else { return plain }
        let idx = plain.index(plain.startIndex, offsetBy: maxPreviewChars)
        return plain[..<idx].trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    // MARK: Footer — watch / read indicator

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: review.kind == .review ? "text.quote" : "eye")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
            Text(review.kind == .review ? "Read review" : "Watched")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

#Preview {
    let sample = Review(
        id: "sample-1",
        username: "davidehrlich",
        title: "Fallen Angels, 1995 - ★★★★½",
        link: "https://letterboxd.com/davidehrlich/film/fallen-angels/",
        pubDateRaw: "Sun, 19 Apr 2026 08:14:23 +0000",
        publishedAt: .now,
        creator: "David Ehrlich",
        reviewHTML: "<p>Wong Kar-wai's restless nocturne feels like a film made of neon and spilled coffee — every frame trembling with the ache of missed connections. A masterclass in mood.</p>",
        rating: "★★★★½",
        movieTitle: "Fallen Angels",
        kind: .review
    )

    return ReviewCard(review: sample)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
