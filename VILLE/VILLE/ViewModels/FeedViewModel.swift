//
//  FeedViewModel.swift
//  VILLE
//
//  Orchestrates the feed: triggers RSS fetches, upserts fresh reviews into
//  SwiftData, and exposes refresh state to `FeedView`.
//
//  The view never queries RSSService directly — it only observes this VM
//  for loading/error state and reads reviews via `@Query` from SwiftData.
//  That's what makes VILLE offline-first: the UI is identical with or
//  without network.
//

import Foundation
import SwiftData
import Observation

/// Hard-coded seed usernames until we build a followed-users manager UI.
/// Feel free to swap in your favourite Letterboxd handles for development.
private let seedUsernames: [String] = [
    "davidehrlich",
    "karstenrunquist",
    "lucy",
]

@Observable
final class FeedViewModel {

    // MARK: Observable state

    /// True while a refresh request is in flight.
    var isRefreshing = false

    /// Human-readable error message from the last refresh attempt, or nil.
    var errorMessage: String?

    /// Usernames currently being followed (in-memory for now).
    /// Future: persist via a `FollowedUser` SwiftData model.
    var followedUsernames: [String]

    // MARK: Dependencies

    private let rss: RSSService
    /// Owned SwiftData context for write-backs. The view passes its own context
    /// in so VM and view share the same container.
    private var modelContext: ModelContext?

    // MARK: Init

    init(rss: RSSService = RSSService(), followedUsernames: [String] = seedUsernames) {
        self.rss = rss
        self.followedUsernames = followedUsernames
    }

    /// Called by `FeedView` in `.task` so the VM can write to SwiftData.
    func bind(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: Actions

    /// Fetch every followed user's feed in parallel and upsert into SwiftData.
    /// Safe to call repeatedly (pull-to-refresh) — idempotent thanks to the
    /// unique `id` attribute on `Review`.
    @MainActor
    func refresh() async {
        guard !isRefreshing else { return }
        guard let context = modelContext else {
            errorMessage = "Feed not ready yet"
            return
        }

        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        let parsed = await rss.fetchFeed(usernames: followedUsernames)
        if parsed.isEmpty && !followedUsernames.isEmpty {
            errorMessage = "No reviews found — check your connection"
            return
        }

        upsert(parsed, into: context)
    }

    // MARK: Persistence

    /// Insert-or-update semantics keyed on `Review.id`.
    /// SwiftData doesn't have a native upsert so we fetch-then-merge per item.
    @MainActor
    private func upsert(_ parsed: [ParsedReview], into context: ModelContext) {
        for p in parsed {
            let id = p.id
            var descriptor = FetchDescriptor<Review>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1

            if let existing = try? context.fetch(descriptor).first {
                // Refresh mutable fields (Letterboxd can edit ratings/reviews).
                existing.title = p.title
                existing.link = p.link
                existing.pubDateRaw = p.pubDateRaw
                existing.publishedAt = p.publishedAt
                existing.creator = p.creator
                existing.reviewHTML = p.reviewHTML
                existing.rating = p.rating
                existing.movieTitle = p.movieTitle
                existing.kind = p.kind
                existing.fetchedAt = .now
            } else {
                let review = Review(
                    id: p.id,
                    username: p.username,
                    title: p.title,
                    link: p.link,
                    pubDateRaw: p.pubDateRaw,
                    publishedAt: p.publishedAt,
                    creator: p.creator,
                    reviewHTML: p.reviewHTML,
                    rating: p.rating,
                    movieTitle: p.movieTitle,
                    kind: p.kind
                )
                context.insert(review)
            }
        }

        do {
            try context.save()
        } catch {
            errorMessage = "Could not save reviews: \(error.localizedDescription)"
            print("FeedViewModel: save failed — \(error)")
        }
    }
}
