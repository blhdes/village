//
//  ReelSession.swift
//  VILLE
//
//  What's on screen right now: the session's `ReelQueue`, the page the
//  reader is on, and the spoilers they chose to reveal. A session is as
//  long as Settings says; then the feed ends. Coming back after a break
//  (30 minutes away) starts a new one.
//
//  Every review that appears is stamped with `lastShownAt`, so
//  `ReelSampler` can put the reviews that have waited longest first.
//

import Foundation
import SwiftData
import Observation

/// Session lengths offered in Settings.
enum SessionLength {
    static let options = [10, 20, 30, 50]
    static let standard = 20
}

@Observable
final class ReelSession {
    /// Scroll id of the end card that follows the last reel.
    static let endPageID = -1

    private(set) var queue = ReelQueue()

    /// Spoiler reviews the user chose to read. Kept until the app quits, so
    /// a review stays uncovered if it comes round again.
    private(set) var revealedSpoilers: Set<String> = []

    private let context: ModelContext

    /// The page on screen: a reel's slot id, or `endPageID`.
    private var currentPageID: Int?
    private var leftAt: Date?

    /// Time away after which coming back starts a new session.
    private let breakLength: TimeInterval = 30 * 60

    init(context: ModelContext) {
        self.context = context
    }

    private var isAtEnd: Bool { currentPageID == Self.endPageID }

    private var currentIndex: Int {
        if isAtEnd { return queue.slots.count }
        return currentPageID.flatMap { queue.index(of: $0) } ?? 0
    }

    // MARK: Building sessions

    /// Keeps the session in line with the saved reviews. The first call, or
    /// one after the feed emptied, picks a new session.
    func sync(with reviews: [Review], length: Int) {
        guard !queue.slots.isEmpty else {
            startNew(with: reviews, length: length)
            return
        }
        queue.sync(with: candidates(reviews), length: length, currentIndex: currentIndex, sessionEnded: isAtEnd)
    }

    /// The session length changed in Settings.
    func resize(to length: Int, reviews: [Review]) {
        queue.resize(to: length, from: candidates(reviews), currentIndex: currentIndex, sessionEnded: isAtEnd)
    }

    func startNew(with reviews: [Review], length: Int) {
        queue.start(length: length, from: candidates(reviews))
        currentPageID = queue.slots.first?.id
        // The first reel is on screen straight away, before any scrolling.
        if let first = queue.slots.first {
            markShown(first.reviewID, in: reviews)
        }
    }

    /// "Keep reading" on the end card. Returns the first new reel, to scroll
    /// to, or nil when there was nothing to add.
    func keepReading(with reviews: [Review], length: Int) -> Int? {
        let firstNew = queue.slots.count
        queue.extend(length: length, from: candidates(reviews))
        guard queue.slots.count > firstNew else { return nil }
        return queue.slots[firstNew].id
    }

    // MARK: Reading

    /// Called as the feed scrolls. Every reel that appears counts as shown.
    func didShowPage(_ pageID: Int, reviews: [Review]) {
        currentPageID = pageID
        guard let index = queue.index(of: pageID) else { return }
        markShown(queue.slots[index].reviewID, in: reviews)
    }

    func revealSpoilers(for reviewID: String) {
        revealedSpoilers.insert(reviewID)
    }

    // MARK: Breaks

    func didLeave() {
        leftAt = .now
    }

    /// Call when VILLE is back on screen. True if it was away long enough
    /// for a new session.
    func didReturn(now: Date = .now) -> Bool {
        guard let leftAt else { return false }
        self.leftAt = nil
        return now.timeIntervalSince(leftAt) >= breakLength
    }

    // MARK: Private

    /// A closure rather than `map(ReelCandidate.init)`, so it stays on the
    /// main actor like the reviews it reads.
    private func candidates(_ reviews: [Review]) -> [ReelCandidate] {
        reviews.map { ReelCandidate($0) }
    }

    private func markShown(_ reviewID: String, in reviews: [Review]) {
        guard let review = reviews.first(where: { $0.id == reviewID }) else { return }
        review.lastShownAt = .now
        do {
            try context.save()
        } catch {
            print("ReelSession: could not save that \(reviewID) was shown — \(error)")
        }
    }
}
