//
//  Review.swift
//  VILLE
//
//  SwiftData model for a single written Letterboxd review.
//
//  Only real reviews are stored — lists and plain "watched" diary entries are
//  dropped by `RSSService`. Reviews stay saved after they fall out of a
//  member's RSS window, so the local library grows over time, up to the
//  limit `LibraryTrimmer` keeps it to. Bookmarked reviews are always kept.
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

    /// When the reader uncovered this spoiler review; nil while it's still
    /// covered. One-way: saved, never set back, so it stays uncovered on
    /// the reel, in Bookmarks and after VILLE quits.
    var spoilersRevealedAt: Date?

    /// Review body as Letterboxd's HTML, with the poster image removed.
    var reviewHTML: String

    /// Words in the review text (`ReviewLength`). Nil for a review saved
    /// before VILLE counted words, until its member's feed brings it
    /// again: such a review never counts as very short.
    var wordCount: Int?

    /// TMDB image paths (append to an image base URL). Nil when TMDB has none.
    var posterPath: String?
    var backdropPath: String?

    /// The film's TMDB galleries: posters (official first, then other
    /// countries' and textless ones) and textless backdrops to rotate
    /// through. Nil until fetched — older reviews fall back to the single
    /// paths above until then.
    var posterPaths: [String]?
    var backdropPaths: [String]?

    /// True once TMDB has been asked for art, even if it had none — avoids
    /// asking again on every launch.
    var artFetched: Bool

    /// When this review last appeared in the feed; nil if never. Sessions
    /// show the reviews that have waited longest first.
    var lastShownAt: Date?

    /// When the reader bookmarked this review; nil if they didn't.
    /// Bookmarked reviews are never trimmed, and stay after their member
    /// is removed (they then leave the feed but stay in Bookmarks).
    var bookmarkedAt: Date?

    /// The poster a bookmark shows, as its place in `posterChoices`: the
    /// one on screen when the review was bookmarked (with posters on), or
    /// the last one picked in Bookmarks. Nil: the official one.
    var bookmarkPosterIndex: Int?

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
        wordCount = parsed.wordCount
        spoilersRevealedAt = nil
        posterPath = nil
        backdropPath = nil
        posterPaths = nil
        backdropPaths = nil
        artFetched = false
        lastShownAt = nil
        bookmarkedAt = nil
        bookmarkPosterIndex = nil
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
        wordCount = parsed.wordCount
        fetchedAt = .now
    }
}

// MARK: - Display helpers

extension Review {
    /// The rating as whole stars plus an optional half (3.5 → 3 and a
    /// half), nil when unrated.
    var starRating: (full: Int, half: Bool)? {
        guard let rating, rating > 0 else { return nil }
        let full = Int(rating)
        return (full, rating - Double(full) >= 0.5)
    }

    /// "Watched Oct 14, 2026", falling back to the publish date.
    var watchedLabel: String {
        let date = (watchedOn ?? publishedAt).formatted(.dateTime.month(.abbreviated).day().year())
        return isRewatch ? String(localized: "Rewatched \(date)") : String(localized: "Watched \(date)")
    }

    var url: URL? { URL(string: link) }

    /// The author's profile on letterboxd.com.
    var authorProfileURL: URL? { URL(string: "https://letterboxd.com/\(username)/") }

    var isBookmarked: Bool { bookmarkedAt != nil }

    /// A spoiler review the reader hasn't uncovered yet (`SpoilerGate`).
    var isSpoilerCovered: Bool { containsSpoilers && spoilersRevealedAt == nil }

    /// A one-liner ("Banger", "absolute cinema"): under
    /// `ReviewLength.shortLimit` words. Settings → Reading can leave these
    /// out of the feed.
    var isVeryShort: Bool {
        guard let wordCount else { return false }
        return wordCount < ReviewLength.shortLimit
    }

    /// A web search for the film ("Title 2026 film"), opened from its title
    /// in the in-app browser, as the mobile app does. The year tells
    /// remakes apart.
    var filmSearchURL: URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        let query = [filmTitle, filmYear.map(String.init), "film"].compactMap { $0 }.joined(separator: " ")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }

    /// True until TMDB has been asked for this film's galleries.
    var needsArt: Bool { !artFetched || posterPaths == nil }

    /// Posters to choose from, official first.
    var posterChoices: [String] {
        if let posterPaths, !posterPaths.isEmpty { return posterPaths }
        return posterPath.map { [$0] } ?? []
    }

    /// Backdrops to choose from.
    var backdropChoices: [String] {
        if let backdropPaths, !backdropPaths.isEmpty { return backdropPaths }
        return backdropPath.map { [$0] } ?? []
    }

    /// One of the film's posters. `pick` is any number: it wraps around the
    /// gallery, and 0 is always the official poster.
    func posterURL(pick: Int) -> URL? {
        Self.imageURL(in: posterChoices, pick: pick, size: "w342")
    }

    /// One of the film's backdrops, chosen the same way as `posterURL(pick:)`.
    func backdropURL(pick: Int) -> URL? {
        Self.imageURL(in: backdropChoices, pick: pick, size: "w1280")
    }

    /// Where `pick` lands in the poster gallery, the way `posterURL(pick:)`
    /// wraps it. Saved as this number, a bookmark keeps the same poster
    /// even if the rest of the gallery arrives later. Nil without posters.
    func posterIndex(pick: Int) -> Int? {
        Self.index(of: pick, in: posterChoices.count)
    }

    /// The poster a bookmark shows, ready for `posterURL(pick:)`.
    var bookmarkPosterPick: Int { bookmarkPosterIndex ?? 0 }

    private static func imageURL(in paths: [String], pick: Int, size: String) -> URL? {
        guard let index = index(of: pick, in: paths.count) else { return nil }
        return TMDBService.imageURL(path: paths[index], size: size)
    }

    /// Any number, wrapped around a gallery of `count` images.
    private static func index(of pick: Int, in count: Int) -> Int? {
        guard count > 0 else { return nil }
        return (pick % count + count) % count
    }
}
