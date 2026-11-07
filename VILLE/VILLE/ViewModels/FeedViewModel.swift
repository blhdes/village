//
//  FeedViewModel.swift
//  VILLE
//
//  Owns everything that changes the local library: refreshing members' RSS
//  feeds, looking members up (Search), following and removing them,
//  bookmarks, trimming old reviews (through `LibraryTrimmer`) and filling
//  in TMDB art (through `FilmArtLoader`). Feeds are saved by
//  `ReviewImporter`. What's on screen lives in `ReelSession`.
//
//  Views read reviews straight from SwiftData with `@Query`, so the feed
//  looks the same online and offline.
//

import Foundation
import SwiftData
import Observation

enum MemberError: LocalizedError {
    case alreadyAdded(String)

    var errorDescription: String? {
        switch self {
        case .alreadyAdded(let username): String(localized: "You already follow “\(username)”.")
        }
    }
}

/// A member Search found, and how many written reviews their feed holds.
struct FoundMember: Equatable {
    let username: String
    let displayName: String
    let reviewCount: Int
}

@Observable
final class FeedViewModel {

    // MARK: Observable state

    /// True while feeds are being fetched: a red dot breathes.
    var isRefreshing: Bool { refreshTask != nil }

    /// Shown as a small banner when a refresh fails completely.
    var errorMessage: String?

    // MARK: Dependencies

    private let context: ModelContext
    private let rss: RSSService
    private let artLoader: FilmArtLoader
    private let trimmer = LibraryTrimmer()
    private let importer = ReviewImporter()

    private var hasRefreshedSinceLaunch = false

    /// The refresh running now, if any. A refresh asked for meanwhile waits
    /// for it instead of starting another.
    private var refreshTask: Task<Void, Never>?

    /// The single art load allowed at a time, and whether another was asked
    /// for while it ran.
    private var artTask: Task<Void, Never>?
    private var artRequestedAgain = false

    init(context: ModelContext, rss: RSSService = RSSService(), artLoader: FilmArtLoader = FilmArtLoader()) {
        self.context = context
        self.rss = rss
        self.artLoader = artLoader
    }

    // MARK: Refresh

    /// Refreshes once per app launch; later calls do nothing.
    func refreshIfNeeded() async {
        guard !hasRefreshedSinceLaunch else { return }
        hasRefreshedSinceLaunch = true
        await refreshAll()
    }

    /// Fetches every member's feed. If a refresh is already running (the
    /// one at launch, say), waits for it instead, so a pull-to-refresh ends
    /// when the new reviews are really in.
    func refreshAll() async {
        #if DEBUG
        // Store screenshots: fictional members, no feeds to fetch.
        guard StoreDemo.current == nil else { return }
        #endif
        if let running = refreshTask {
            await running.value
            return
        }
        let task = Task { await fetchAllFeeds() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    /// Fetches every member's feed in parallel. One failing member doesn't
    /// stop the rest; the banner only appears if every member failed.
    private func fetchAllFeeds() async {
        let members: [FollowedUser]
        do {
            members = try context.fetch(FetchDescriptor<FollowedUser>())
        } catch {
            print("FeedViewModel: could not load members — \(error)")
            errorMessage = String(localized: "Couldn’t load your saved members.")
            return
        }
        guard !members.isEmpty else { return }

        let rss = self.rss
        let results = await withTaskGroup(of: (String, Result<UserFeed, Error>).self) { group in
            for member in members {
                let username = member.username
                group.addTask {
                    do {
                        return (username, .success(try await rss.fetchUserFeed(username: username)))
                    } catch {
                        return (username, .failure(error))
                    }
                }
            }
            var collected: [(String, Result<UserFeed, Error>)] = []
            for await result in group { collected.append(result) }
            return collected
        }

        var failures = 0
        for (username, result) in results {
            switch result {
            case .success(let feed):
                store(feed, for: username)
            case .failure(let error):
                failures += 1
                print("FeedViewModel: refresh failed for \(username) — \(error)")
            }
        }
        save()

        errorMessage = failures == members.count
            ? String(localized: "Couldn’t reach Letterboxd. Showing saved reviews.")
            : nil

        loadMissingArt()
    }

    // MARK: Members

    /// Validates the username against Letterboxd, then saves the member and
    /// their current reviews. Takes a username or a link, including the
    /// boxd.it short links the Letterboxd app shares (`LetterboxdLink`).
    /// Throws a user-readable error on failure.
    func addMember(_ input: String) async throws {
        let username = try await LetterboxdLink.username(from: input)
        guard try !isFollowed(username) else {
            throw MemberError.alreadyAdded(username)
        }

        let feed = try await rss.fetchUserFeed(username: username)
        context.insert(FollowedUser(username: username, displayName: feed.displayName ?? username))
        importFeed(feed, for: username)
        save()

        loadMissingArt()
    }

    /// Search: finds a member by username or link without following them,
    /// with one request to their RSS feed. Their reviews are saved, so
    /// their feed opens at once; while nobody follows them, they're
    /// deleted at the next launch (`LibraryTrimmer`), bookmarks apart.
    func lookUp(_ input: String) async throws -> FoundMember {
        let username = try await LetterboxdLink.username(from: input)
        return try await lookUp(username: username)
    }

    /// The same for a username already known, like a suggestion opened to read.
    func lookUp(username: String) async throws -> FoundMember {
        let feed = try await rss.fetchUserFeed(username: username)
        importFeed(feed, for: username)
        save()

        loadMissingArt()
        return FoundMember(username: username, displayName: feed.displayName ?? username, reviewCount: feed.reviews.count)
    }

    /// Follows a member just looked up. Their reviews are saved already,
    /// so nothing is fetched; following twice does nothing.
    func follow(username: String, displayName: String) {
        do {
            guard try !isFollowed(username) else { return }
        } catch {
            print("FeedViewModel: could not check whether \(username) is followed — \(error)")
            return
        }
        context.insert(FollowedUser(username: username, displayName: displayName))
        save()
    }

    /// Removes members together with every review saved from them, except
    /// the bookmarked ones: those stay in Bookmarks, out of the feed.
    func removeMembers(_ members: [FollowedUser]) {
        for member in members {
            let username = member.username
            do {
                try context.delete(model: Review.self, where: #Predicate { $0.username == username && $0.bookmarkedAt == nil })
            } catch {
                print("FeedViewModel: could not delete reviews for \(username) — \(error)")
            }
            context.delete(member)
        }
        save()
    }

    // MARK: Bookmarks

    /// Bookmarks the review, or takes its bookmark off. A new bookmark
    /// keeps the poster on screen (`posterPick`, nil with posters off).
    /// Taking it off leaves the poster as it was, so the review doesn't
    /// change on the Bookmarks page while it's being read there.
    func toggleBookmark(_ review: Review, posterPick: Int?) {
        if review.isBookmarked {
            review.bookmarkedAt = nil
        } else {
            review.bookmarkedAt = .now
            review.bookmarkPosterIndex = posterPick.flatMap { review.posterIndex(pick: $0) }
        }
        save()
    }

    /// Moves a bookmark on to the film's next poster, and keeps that one.
    func showNextPoster(of review: Review) {
        review.bookmarkPosterIndex = review.posterIndex(pick: review.bookmarkPosterPick + 1)
        save()
    }

    // MARK: Library size

    /// Deletes the reviews past `LibraryTrimmer`'s limit. Call once at
    /// launch, before the feed picks a session: a review on screen must
    /// never be deleted under the reader.
    func trimLibrary() {
        do {
            let deleted = try trimmer.trim(in: context)
            guard deleted > 0 else { return }
            print("FeedViewModel: trimmed \(deleted) old reviews from the library")
            save()
        } catch {
            print("FeedViewModel: could not trim the library — \(error)")
        }
    }

    // MARK: Persistence

    /// Saves a followed member's feed after a refresh. The member can be
    /// removed while their feed is still downloading: saving it then would
    /// bring their reviews back.
    private func store(_ feed: UserFeed, for username: String) {
        do {
            guard try isFollowed(username) else {
                print("FeedViewModel: \(username) was removed during the refresh — skipping their feed")
                return
            }
        } catch {
            print("FeedViewModel: could not look up member \(username) — \(error)")
            return
        }
        importFeed(feed, for: username)
    }

    private func importFeed(_ feed: UserFeed, for username: String) {
        do {
            try importer.importFeed(feed, for: username, into: context)
        } catch {
            print("FeedViewModel: could not save the feed of \(username) — \(error)")
        }
    }

    private func isFollowed(_ username: String) throws -> Bool {
        try context.fetchCount(FetchDescriptor<FollowedUser>(predicate: #Predicate { $0.username == username })) > 0
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("FeedViewModel: save failed — \(error)")
            errorMessage = String(localized: "Couldn’t save reviews on this device.")
        }
    }

    // MARK: TMDB art

    /// True while TMDB art is being looked up, so reels can hold the
    /// poster's place with a skeleton instead of leaving a gap.
    var isLoadingArt: Bool { artTask != nil }

    /// Starts filling in missing art without waiting for it, so adding a
    /// member finishes as soon as their reviews are saved. Only one load runs
    /// at a time; a call made meanwhile adds one more pass afterwards, for
    /// the reviews saved since the first one began.
    private func loadMissingArt() {
        guard artTask == nil else {
            artRequestedAgain = true
            return
        }
        artTask = Task {
            repeat {
                artRequestedAgain = false
                await fetchMissingArt()
            } while artRequestedAgain
            artTask = nil
        }
    }

    private func fetchMissingArt() async {
        do {
            try await artLoader.fillMissingArt(in: context)
        } catch {
            print("FeedViewModel: could not load reviews for art — \(error)")
            return
        }
        save()
    }
}
