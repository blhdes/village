//
//  Review.swift
//  VILLE
//
//  SwiftData model for a single written Letterboxd review.
//
//  Only real reviews are stored — lists and plain "watched" diary entries are
//  dropped by `RSSService`. Reviews are never deleted when they fall out of a
//  member's RSS window, so the local library keeps growing over time.
//

import Foundation
import SwiftData

@Model
final class Review {
    /// RSS `<guid>` — e.g. "letterboxd-review-1537861745". Stable across edits.
    @Attribute(.unique) var id: String

    /// Lowercase Letterboxd handle of the author (matches `FollowedUser.username`).
    var username: String

    /// `<dc:creator>` — the author's display name.
    var authorName: String

    /// Direct link to the review on letterboxd.com.
    var link: String

    var publishedAt: Date

    /// `<letterboxd:watchedDate>` — the day the author logged the film.
    var watchedOn: Date?

    var filmTitle: String
    var filmYear: Int?

    /// `<tmdb:movieId>` — used to fetch the poster and backdrop.
    var tmdbID: Int?

    /// Star rating from 0.5 to 5, or nil when the author didn't rate.
    var rating: Double?

    var liked: Bool
    var isRewatch: Bool
    var containsSpoilers: Bool

    /// Review body as Letterboxd's HTML, with the poster image removed.
    var reviewHTML: String

    /// TMDB image paths (append to an image base URL). Nil when TMDB has none.
    var posterPath: String?
    var backdropPath: String?

    /// True once TMDB has been asked for art, even if it had none — avoids
    /// asking again on every launch.
    var artFetched: Bool

    var fetchedAt: Date

    init(from parsed: ParsedReview) {
        id = parsed.id
        username = parsed.username
        authorName = parsed.authorName
        link = parsed.link
        publishedAt = parsed.publishedAt
        watchedOn = parsed.watchedOn
        filmTitle = parsed.filmTitle
        filmYear = parsed.filmYear
        tmdbID = parsed.tmdbID
        rating = parsed.rating
        liked = parsed.liked
        isRewatch = parsed.isRewatch
        containsSpoilers = parsed.containsSpoilers
        reviewHTML = parsed.reviewHTML
        posterPath = nil
        backdropPath = nil
        artFetched = false
        fetchedAt = .now
    }

    /// Refresh the fields an author can change after posting.
    func update(from parsed: ParsedReview) {
        authorName = parsed.authorName
        watchedOn = parsed.watchedOn
        rating = parsed.rating
        liked = parsed.liked
        isRewatch = parsed.isRewatch
        containsSpoilers = parsed.containsSpoilers
        reviewHTML = parsed.reviewHTML
        fetchedAt = .now
    }
}

// MARK: - Display helpers

extension Review {
    /// "★★★½" — empty when unrated.
    var stars: String {
        guard let rating, rating > 0 else { return "" }
        let full = Int(rating)
        let half = rating - Double(full) >= 0.5
        return String(repeating: "★", count: full) + (half ? "½" : "")
    }

    /// "Watched Oct 14, 2026", falling back to the publish date.
    var watchedLabel: String {
        let date = (watchedOn ?? publishedAt).formatted(.dateTime.month(.abbreviated).day().year())
        return isRewatch ? "Rewatched \(date)" : "Watched \(date)"
    }

    var url: URL? { URL(string: link) }

    var posterURL: URL? { TMDBService.imageURL(path: posterPath, size: "w342") }
    var backdropURL: URL? { TMDBService.imageURL(path: backdropPath, size: "w1280") }
}
