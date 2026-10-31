//
//  FeedViewModel.swift
//  VILLE
//
//  Owns everything that changes the local library: refreshing members' RSS
//  feeds, adding and removing members, bookmarks, trimming old reviews
//  (through `LibraryTrimmer`) and filling in TMDB art (through
//  `FilmArtLoader`). What's on screen lives in `ReelSession`.
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

@Observable
final class FeedViewModel {

    // MARK: Observable state

    private(set) var isRefreshing = false

    /// Shown as a small banner when a refresh fails completely.
    var errorMessage: String?

    // MARK: Dependencies

    private let context: ModelContext
    private let rss: RSSService
    private let artLoader: FilmArtLoader
    private let trimmer = LibraryTrimmer()

    private var hasRefreshedSinceLaunch = false

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

    /// Fetches every member's feed in parallel. One failing member doesn't
    /// stop the rest; the banner only appears if every member failed.
    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let members: [FollowedUser]
        do {
            members = try context.fetch(FetchDescriptor<FollowedUser>())
        } catch {
            print("FeedViewModel: could not load members — \(error)")
            errorMessage = String(localized: "Couldn't load your saved members.")
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
            ? String(localized: "Couldn't reach Letterboxd. Showing saved reviews.")
            : nil

        loadMissingArt()
    }

    // MARK: Members

    /// Validates the username against Letterboxd, then saves the member and
    /// their current reviews. Throws a user-readable error on failure.
    func addMember(_ input: String) async throws {
        guard let username = RSSService.normalizeUsername(input) else {
            throw RSSError.invalidUsername(input)
        }
        let existing = FetchDescriptor<FollowedUser>(predicate: #Predicate { $0.username == username })
        guard try context.fetchCount(existing) == 0 else {
            throw MemberError.alreadyAdded(username)
        }

        let feed = try await rss.fetchUserFeed(username: username)
        context.insert(FollowedUser(username: username, displayName: feed.displayName ?? username))
        store(feed, for: username)
        save()

        loadMissingArt()
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

    /// Bookmarks the review, or takes its bookmark off.
    func toggleBookmark(_ review: Review) {
        review.bookmarkedAt = review.isBookmarked ? nil : .now
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

    /// Insert-or-update by review id. Reviews that dropped out of the RSS
    /// window are kept, so the library grows over time.
    private func store(_ feed: UserFeed, for username: String) {
        let memberDescriptor = FetchDescriptor<FollowedUser>(predicate: #Predicate { $0.username == username })
        let member: FollowedUser?
        do {
            member = try context.fetch(memberDescriptor).first
        } catch {
            print("FeedViewModel: could not look up member \(username) — \(error)")
            return
        }
        // The member can be removed while their feed is still downloading.
        // Saving it then would bring back reviews nothing can delete.
        guard let member else {
            print("FeedViewModel: \(username) was removed during the refresh — skipping their feed")
            return
        }

        let descriptor = FetchDescriptor<Review>(predicate: #Predicate { $0.username == username })
        let saved: [Review]
        do {
            saved = try context.fetch(descriptor)
        } catch {
            print("FeedViewModel: could not read saved reviews for \(username) — \(error)")
            return
        }
        let savedByID = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for parsed in feed.reviews {
            if let review = savedByID[parsed.id] {
                review.update(from: parsed)
            } else {
                context.insert(Review(from: parsed))
            }
        }

        if let name = feed.displayName {
            member.displayName = name
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("FeedViewModel: save failed — \(error)")
            errorMessage = String(localized: "Couldn't save reviews on this device.")
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
