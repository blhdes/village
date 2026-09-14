//
//  Review.swift
//  VILLE
//
//  SwiftData model representing a single Letterboxd review or watch entry.
//  Mirrors the `Review` interface from the reference project
//  (`types/database.ts` in ville-du-cinema-mobile).
//
//  `@Model` makes this class the persistence unit AND an observable object —
//  SwiftUI views that observe instances will refresh automatically.
//

import Foundation
import SwiftData

/// Distinguishes plain "Watched on X" entries from actual written reviews.
/// Mirrors the `'review' | 'watch'` union in the RN project.
enum ReviewKind: String, Codable {
    case review
    case watch
}

@Model
final class Review {
    /// Stable unique ID — `"<username>-<link>"` — used as the de-duplication key
    /// when merging fresh RSS results into the cache.
    @Attribute(.unique) var id: String

    /// Letterboxd username the review was fetched from (lowercase handle).
    var username: String

    /// Raw RSS `<title>` — e.g. "Fallen Angels, 1995 - ★★★★".
    var title: String

    /// Direct link to the review on letterboxd.com.
    var link: String

    /// Original `<pubDate>` string from the RSS feed (RFC 822).
    /// Kept as-is so we can reparse on demand; `publishedAt` is the derived Date.
    var pubDateRaw: String

    /// Parsed publish date — used for sorting, grouping, and display.
    var publishedAt: Date

    /// `<dc:creator>` — human-readable display name (falls back to username).
    var creator: String

    /// Sanitised HTML body of the review. Empty for `.watch` entries.
    var reviewHTML: String

    /// Star rating string extracted from the title — e.g. "★★★½". Empty if none.
    var rating: String

    /// Movie title stripped of year + rating suffix — e.g. "Fallen Angels".
    var movieTitle: String

    /// Whether this is a full review or just a watch log entry.
    var kind: ReviewKind

    /// Cache insertion timestamp — used for ordering fallbacks and eviction.
    var fetchedAt: Date

    init(
        id: String,
        username: String,
        title: String,
        link: String,
        pubDateRaw: String,
        publishedAt: Date,
        creator: String,
        reviewHTML: String,
        rating: String,
        movieTitle: String,
        kind: ReviewKind,
        fetchedAt: Date = .now
    ) {
        self.id = id
        self.username = username
        self.title = title
        self.link = link
        self.pubDateRaw = pubDateRaw
        self.publishedAt = publishedAt
        self.creator = creator
        self.reviewHTML = reviewHTML
        self.rating = rating
        self.movieTitle = movieTitle
        self.kind = kind
        self.fetchedAt = fetchedAt
    }
}

// MARK: - Derived convenience

extension Review {
    /// Formatted display date — "Apr 20, 2026".
    var displayDate: String {
        publishedAt.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// Plain-text preview of the review body (tags stripped).
    var plainTextPreview: String {
        reviewHTML.strippingHTMLTags()
    }
}

// MARK: - HTML helper (tiny, stateless, zero-dep)

extension String {
    /// Mirror of `stripHtml()` from `utils/html.ts` in the RN project.
    /// Removes all HTML tags and trims whitespace. Not a security boundary —
    /// meant purely for previews, never for rendering untrusted content.
    func strippingHTMLTags() -> String {
        let pattern = "<[^>]*>"
        let plain = self.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return plain.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
