//
//  ReelSampler.swift
//  VILLE
//
//  Decides which reviews make it into a session, and in what order:
//
//  1. Reviews never shown come first, newest first; then the ones shown
//     longest ago. A little chance picks among the most-waiting ones, so
//     sessions don't keep repeating the same groups.
//  2. Members take turns, so one prolific member can't fill a session.
//  3. The same member or the same film never appears twice in a row when
//     there's any way to avoid it.
//

import Foundation

/// What the sampler needs to know about a review.
struct ReelCandidate {
    let id: String
    let author: String
    /// Same value for every review of the same film.
    let film: String
    let publishedAt: Date
    let lastShownAt: Date?
    /// Left out of new picks by Settings → Reading (a very short review,
    /// or one already shown, with those switches on). A reel already
    /// placed stays.
    let isHidden: Bool
}

extension ReelCandidate {
    init(_ review: Review, rules: ReadingRules) {
        id = review.id
        author = review.username
        film = review.tmdbID.map { "tmdb:\($0)" } ?? "\(review.filmTitle.lowercased())|\(review.filmYear ?? 0)"
        publishedAt = review.publishedAt
        lastShownAt = review.lastShownAt
        isHidden = !rules.allows(review)
    }
}

enum ReelSampler {
    /// Picks up to `count` reviews and puts them in reading order.
    /// `previous` is the reel just before them, if any, so its member and
    /// film aren't repeated straight away.
    static func pick(_ count: Int, from candidates: [ReelCandidate], after previous: ReelCandidate?) -> [ReelCandidate] {
        guard count > 0 else { return [] }

        let unseen = candidates
            .filter { $0.lastShownAt == nil }
            .sorted { $0.publishedAt > $1.publishedAt }
        let seen = candidates
            .filter { $0.lastShownAt != nil }
            .sorted { ($0.lastShownAt ?? .distantPast) < ($1.lastShownAt ?? .distantPast) }

        var picked = takeTurns(count, from: mostWaiting(unseen, for: count))
        if picked.count < count {
            let missing = count - picked.count
            picked += takeTurns(missing, from: mostWaiting(seen, for: missing))
        }
        return arrange(picked, after: previous)
    }

    // MARK: Private

    /// The front of a list sorted by waiting time, twice as long as needed:
    /// the extra half leaves room for chance.
    private static func mostWaiting(_ sorted: [ReelCandidate], for count: Int) -> [ReelCandidate] {
        Array(sorted.prefix(count * 2))
    }

    /// Members take turns in a random order, each giving one random review
    /// from the pool, until `count` are picked or the pool runs dry.
    private static func takeTurns(_ count: Int, from pool: [ReelCandidate]) -> [ReelCandidate] {
        var byAuthor = Dictionary(grouping: pool, by: \.author).mapValues { $0.shuffled() }
        var picked: [ReelCandidate] = []

        while picked.count < count, !byAuthor.isEmpty {
            for author in byAuthor.keys.shuffled() {
                guard picked.count < count, var reviews = byAuthor[author], let next = reviews.popLast() else { continue }
                picked.append(next)
                byAuthor[author] = reviews.isEmpty ? nil : reviews
            }
        }
        return picked
    }

    /// Places the reviews one by one, never right after the same member or
    /// film if another choice exists. The member with the most reviews left
    /// goes first, so their reviews spread out instead of bunching at the end.
    private static func arrange(_ picked: [ReelCandidate], after previous: ReelCandidate?) -> [ReelCandidate] {
        var pool = picked.shuffled()
        var ordered: [ReelCandidate] = []
        var last = previous

        while !pool.isEmpty {
            let left = Dictionary(grouping: pool, by: \.author).mapValues(\.count)
            let allowed = pool.indices.filter { !clashes(pool[$0], with: last) }
            let choices = allowed.isEmpty ? Array(pool.indices) : allowed
            // `max(by:)` keeps the first of equals, and the pool is shuffled, so ties go to chance.
            let index = choices.max { left[pool[$0].author, default: 0] < left[pool[$1].author, default: 0] } ?? 0

            let next = pool.remove(at: index)
            ordered.append(next)
            last = next
        }
        return ordered
    }

    private static func clashes(_ candidate: ReelCandidate, with previous: ReelCandidate?) -> Bool {
        guard let previous else { return false }
        return candidate.author == previous.author || candidate.film == previous.film
    }
}
