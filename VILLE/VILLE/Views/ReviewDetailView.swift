//
//  ReviewDetailView.swift
//  VILLE
//

import SwiftUI
import UIKit

struct ReviewDetailView: View {
    let review: Review
    @Environment(\.dismiss) private var dismiss

    @State private var rendered: AttributedString?

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    reviewBody
                    footerLink
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { renderHTML() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(review.movieTitle)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Text(review.creator)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                if !review.rating.isEmpty {
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(review.rating)
                        .font(.subheadline)
                        .foregroundStyle(.yellow.opacity(0.9))
                }
                Text("·")
                    .foregroundStyle(.white.opacity(0.3))
                Text(review.displayDate)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var reviewBody: some View {
        if let rendered {
            Text(rendered)
                .font(.system(.body, design: .serif))
                .lineSpacing(6)
                .textSelection(.enabled)
        } else if review.reviewHTML.isEmpty {
            Text("This entry is a watch log — no written review.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.5))
                .italic()
        } else {
            Text(review.plainTextPreview)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(6)
        }
    }

    private var footerLink: some View {
        Link(destination: URL(string: review.link) ?? URL(string: "https://letterboxd.com")!) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square")
                Text("Read on Letterboxd")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule().fill(.ultraThinMaterial)
            }
        }
        .padding(.top, 20)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.02, blue: 0.04),
                .black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func renderHTML() {
        guard !review.reviewHTML.isEmpty else { return }
        let html = review.reviewHTML
        Task.detached(priority: .userInitiated) {
            guard let data = html.data(using: .utf8) else { return }
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]
            guard let ns = try? NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            ) else { return }

            let mutable = NSMutableAttributedString(attributedString: ns)

            mutable.addAttribute(
                .foregroundColor,
                value: UIColor.white.withAlphaComponent(0.9),
                range: NSRange(location: 0, length: mutable.length)
            )

            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                .withDesign(.serif) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let baseFont = UIFont(descriptor: descriptor, size: 0)

            mutable.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: mutable.length))

            mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length), options: []) { value, range, _ in
                guard let font = value as? UIFont else { return }
                let traits = font.fontDescriptor.symbolicTraits
                var newDesc = baseFont.fontDescriptor
                if let adjusted = newDesc.withSymbolicTraits(traits) {
                    newDesc = adjusted
                }
                let newFont = UIFont(descriptor: newDesc, size: baseFont.pointSize)
                mutable.addAttribute(.font, value: newFont, range: range)
            }

            let attributed = AttributedString(mutable)
            await MainActor.run { self.rendered = attributed }
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
        reviewHTML: "<p>Wong Kar-wai's restless nocturne feels like a film made of neon and spilled coffee — every frame trembling with the ache of missed connections.</p><p>A masterclass in mood.</p>",
        rating: "★★★★½",
        movieTitle: "Fallen Angels",
        kind: .review
    )

    return NavigationStack {
        ReviewDetailView(review: sample)
    }
    .preferredColorScheme(.dark)
}
