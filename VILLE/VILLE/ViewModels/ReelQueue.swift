//
//  ReelQueue.swift
//  VILLE
//
//  The reels of the current visit, in order. A session holds as many
//  reviews as Settings allows, chosen by `ReelSampler`; after the last one
//  the feed shows its end card. "Keep reading" adds one more session.
//
//  Reviews that arrive mid-session (a refresh, a newly added member) compete
//  for the upcoming reels. The reel on screen and the next one never change,
//  so nothing moves under the reader's finger.
//
//  Reviews Settings → Reading hides (`ReelCandidate.isHidden`) are never
//  picked, but a reel already placed stays until the reader is past it.
//

import Foundation

/// One page in the feed. A review can come back in a later session, so each
/// slot gets its own id for the scroll view, plus the random numbers that
/// pick this appearance's backdrop and poster.
struct ReelSlot: Identifiable, Hashable {
    let id: Int
    let reviewID: String
    let backdropPick: Int
    let posterPick: Int
}

struct ReelQueue {
    private(set) var slots: [ReelSlot] = []

    /// Sessions in this visit: one, plus one per "Keep reading".
    private var sessions = 1
    private var knownIDs: Set<String> = []
    private var nextSlotID = 0

    /// Replaces the reels with a fresh session.
    mutating func start(length: Int, from candidates: [ReelCandidate]) {
        slots = []
        sessions = 1
        let pickable = Self.pickable(candidates)
        knownIDs = Set(pickable.map(\.id))
        append(ReelSampler.pick(length, from: pickable, after: nil))
    }

    /// Brings the queue in line with the saved reviews: drops deleted ones
    /// and lets new arrivals into the upcoming reels. Once the end card is
    /// showing, the session is over and new reviews wait for the next one.
    /// `currentSlotID` is the reel on screen, found again after the drop:
    /// reels leaving before it (an unfollowed member's) mustn't shift where
    /// the session goes on from.
    mutating func sync(with candidates: [ReelCandidate], length: Int, currentSlotID: Int?, sessionEnded: Bool) {
        let ids = Set(candidates.map(\.id))
        // A review only arrives if a session could pick it.
        let pickableIDs = Set(Self.pickable(candidates).map(\.id))
        let arrived = !pickableIDs.isSubset(of: knownIDs)
        knownIDs = pickableIDs

        // Where the reader is, counted in the reels that stay. If the reel
        // on screen leaves too, the next one that stays takes its place.
        let current = currentSlotID.flatMap { index(of: $0) } ?? 0
        let currentIndex = slots[..<current].count(where: { ids.contains($0.reviewID) })

        let countBefore = slots.count
        slots.removeAll { !ids.contains($0.reviewID) }
        let removed = slots.count < countBefore

        guard arrived || removed, !sessionEnded else { return }
        replanUpcoming(length: length, from: candidates, currentIndex: currentIndex)
    }

    /// Applies Settings → Reading to the reels not reached yet: a new
    /// session length, or very short reviews hidden or shown again.
    mutating func update(length: Int, from candidates: [ReelCandidate], currentIndex: Int, sessionEnded: Bool) {
        knownIDs = Set(Self.pickable(candidates).map(\.id))
        guard !sessionEnded else { return }
        replanUpcoming(length: length, from: candidates, currentIndex: currentIndex)
    }

    /// "Keep reading": room for one more session after this one.
    mutating func extend(length: Int, from candidates: [ReelCandidate]) {
        sessions += 1
        let placed = Set(slots.map(\.reviewID))
        let pickable = Self.pickable(candidates)
        var pool = pickable.filter { !placed.contains($0.id) }
        // Everything was read during this visit: go round again.
        if pool.isEmpty {
            pool = pickable.filter { $0.id != slots.last?.reviewID }
        }
        append(ReelSampler.pick(length, from: pool, after: candidate(for: slots.last, in: candidates)))
    }

    func index(of slotID: Int) -> Int? {
        slots.firstIndex { $0.id == slotID }
    }

    // MARK: Private

    /// Re-picks every reel after the next one, from the reviews not placed
    /// before that point. If the session shrank past the current reel, it
    /// now ends right after it.
    private mutating func replanUpcoming(length: Int, from candidates: [ReelCandidate], currentIndex: Int) {
        let capacity = length * sessions
        let keep = min(currentIndex + 2, slots.count, max(capacity, currentIndex + 1))
        slots.removeSubrange(keep...)

        let placed = Set(slots.map(\.reviewID))
        let pool = Self.pickable(candidates).filter { !placed.contains($0.id) }
        append(ReelSampler.pick(capacity - slots.count, from: pool, after: candidate(for: slots.last, in: candidates)))
    }

    /// The reviews a session may pick.
    private static func pickable(_ candidates: [ReelCandidate]) -> [ReelCandidate] {
        candidates.filter { !$0.isHidden }
    }

    private func candidate(for slot: ReelSlot?, in candidates: [ReelCandidate]) -> ReelCandidate? {
        guard let slot else { return nil }
        return candidates.first { $0.id == slot.reviewID }
    }

    private mutating func append(_ picked: [ReelCandidate]) {
        for candidate in picked {
            slots.append(ReelSlot(
                id: nextSlotID,
                reviewID: candidate.id,
                backdropPick: Int.random(in: 0..<1_000),
                posterPick: Int.random(in: 0..<1_000)
            ))
            nextSlotID += 1
        }
    }
}
