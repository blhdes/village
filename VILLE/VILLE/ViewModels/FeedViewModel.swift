//
//  FeedViewModel.swift
//  VILLE
//
//  Owns everything that changes the local library: refreshing members' RSS
//  feeds, adding and removing members, and filling in TMDB art (through
//  `FilmArtLoader`). Also keeps the session's `ReelQueue`.
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
        case .alreadyAdded(let username): "You already follow “\(username)”."
        }
    }
}

@Observable
final class FeedViewModel {

    // MARK: Observable state

    private(set) var queue = ReelQueue()
    private(set) var isRefreshing = false

    /// Shown as a small banner when a refresh fails completely.
    var errorMessage: String?

    /// Spoiler reviews the user chose to read. Kept for the session only, so
    /// a review stays uncovered when it comes round again.
    private(set) var revealedSpoilers: Set<String> = []

    // MARK: Dependencies

    private let context: ModelContext
    private let rss: RSSService
    private let artLoader: FilmArtLoader

    private var hasRefreshedThisSession = false
    private var currentIndex = 0

    init(context: ModelContext, rss: RSSService = RSSService(), artLoader: FilmArtLoader = FilmArtLoader()) {
        self.context = context
        self.rss = rss
        self.artLoader = artLoader
    }

    // MARK: Queue

    func syncQueue(with reviewIDs: [String]) {
        if reviewIDs.isEmpty { currentIndex = 0 }
        queue.sync(with: reviewIDs, currentIndex: currentIndex)
        queue.extendIfNeeded(currentIndex: currentIndex, reviewIDs: reviewIDs)
    }

    /// Called as the user swipes, so the next round is ready before they need it.
    func didShowSlot(_ slotID: Int, reviewIDs: [String]) {
        guard let index = queue.index(of: slotID) else { return }
        currentIndex = index
        queue.extendIfNeeded(currentIndex: index, reviewIDs: reviewIDs)
    }

    func revealSpoilers(for reviewID: String) {
        revealedSpoilers.insert(reviewID)
    }

    // MARK: Refresh

    /// Refreshes once per app launch; later calls do nothing.
    func refreshIfNeeded() async {
        guard !hasRefreshedThisSession else { return }
        hasRefreshedThisSession = true
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
            errorMessage = "Couldn't load your saved members."
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
            ? "Couldn't reach Letterboxd. Showing saved reviews."
            : nil

        await fetchMissingArt()
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

        await fetchMissingArt()
    }

    /// Removes members together with every review saved from them.
    func removeMembers(_ members: [FollowedUser]) {
        for member in members {
            let username = member.username
            do {
                try context.delete(model: Review.self, where: #Predicate { $0.username == username })
            } catch {
                print("FeedViewModel: could not delete reviews for \(username) — \(error)")
            }
            context.delete(member)
        }
        save()
    }

    // MARK: Persistence

    /// Insert-or-update by review id. Reviews that dropped out of the RSS
    /// window are kept, so the library grows over time.
    private func store(_ feed: UserFeed, for username: String) {
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
            let memberDescriptor = FetchDescriptor<FollowedUser>(predicate: #Predicate { $0.username == username })
            do {
                try context.fetch(memberDescriptor).first?.displayName = name
            } catch {
                print("FeedViewModel: could not update display name for \(username) — \(error)")
            }
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("FeedViewModel: save failed — \(error)")
            errorMessage = "Couldn't save reviews on this device."
        }
    }

    // MARK: TMDB art

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
