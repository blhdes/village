//
//  ReelQueue.swift
//  VILLE
//
//  The order reels appear in. Each session starts with every saved review
//  shuffled — a "round". No review repeats until the round is used up; then
//  a fresh shuffled round is appended, so the feed never ends.
//
//  Reviews that arrive mid-session (a refresh, a newly added member) are
//  slipped in at random spots ahead of the current reel.
//

import Foundation

/// One page in the feed. A review can appear in several slots across rounds,
/// so each slot gets its own id for the scroll view.
struct ReelSlot: Identifiable, Hashable {
    let id: Int
    let reviewID: String
}

struct ReelQueue {
    private(set) var slots: [ReelSlot] = []

    /// Reviews already placed in the latest round.
    private var placedThisRound: Set<String> = []
    private var nextSlotID = 0

    /// How close to the end the user gets before the next round is added.
    private let lookahead = 3

    /// Brings the queue in line with the reviews saved on the device.
    mutating func sync(with reviewIDs: [String], currentIndex: Int) {
        let available = Set(reviewIDs)

        // Drop reviews that no longer exist (e.g. their member was removed).
        slots.removeAll { !available.contains($0.reviewID) }
        placedThisRound.formIntersection(available)

        guard !slots.isEmpty else {
            appendRound(reviewIDs)
            return
        }

        let fresh = reviewIDs.filter { !placedThisRound.contains($0) }
        let lowerBound = min(currentIndex + 1, slots.count)
        for reviewID in fresh.shuffled() {
            slots.insert(makeSlot(reviewID), at: Int.random(in: lowerBound...slots.count))
            placedThisRound.insert(reviewID)
        }
    }

    /// Adds another shuffled round once the user nears the end.
    mutating func extendIfNeeded(currentIndex: Int, reviewIDs: [String]) {
        guard currentIndex >= slots.count - lookahead else { return }
        appendRound(reviewIDs)
    }

    func index(of slotID: Int) -> Int? {
        slots.firstIndex { $0.id == slotID }
    }

    // MARK: Private

    private mutating func appendRound(_ reviewIDs: [String]) {
        guard !reviewIDs.isEmpty else { return }

        var round = reviewIDs.shuffled()
        // Never show the same review twice in a row across the round boundary.
        if round.count > 1, round.first == slots.last?.reviewID {
            round.swapAt(0, Int.random(in: 1..<round.count))
        }

        for reviewID in round {
            slots.append(makeSlot(reviewID))
        }
        placedThisRound = Set(round)
    }

    private mutating func makeSlot(_ reviewID: String) -> ReelSlot {
        defer { nextSlotID += 1 }
        return ReelSlot(id: nextSlotID, reviewID: reviewID)
    }
}
