//
//  RatingRequest.swift
//  VILLE
//
//  Asks for a rating on "Fin" cards, a pause between sessions rather than
//  the middle of a review: first on the third one, when the reader has
//  finished three sessions and knows what VILLE is like, then up to three
//  more times, each on a Fin card at least a month after the last ask.
//
//  The question is Apple's own (`requestReview`). iOS shows it at most
//  three times in 365 days, and never in TestFlight, so the fourth ask
//  waits until a year after the first. Opening the review page from
//  Settings → About ends the asking.
//

import SwiftUI
import StoreKit

enum RatingRequest {
    /// `@AppStorage` keys: Fin cards reached (counted up to the first ask),
    /// how many times VILLE asked, and when it first and last did (seconds
    /// since 2001, 0 for never).
    static let finCardsKey = "finCardsSeen"
    static let askCountKey = "ratingAskCount"
    static let firstAskKey = "ratingFirstAsk"
    static let lastAskKey = "ratingLastAsk"

    /// The Fin card that asks first.
    static let firstFinCard = 3
    /// The first ask and three more.
    static let maxAsks = 4
    /// At least this long between two asks.
    static let gap: TimeInterval = 30 * 24 * 60 * 60

    /// iOS shows the question at most this many times in a year: one more
    /// ask inside that year would be lost.
    static let applePerYear = 3
    static let year: TimeInterval = 365 * 24 * 60 * 60

    /// Time on the card before asking, so "Fin" lands first.
    static let pause: Duration = .seconds(1.5)

    /// Whether a Fin card on screen should ask now.
    static func isDue(finCards: Int, asks: Int, firstAsk: Date?, lastAsk: Date?, now: Date = .now) -> Bool {
        guard finCards >= firstFinCard, asks < maxAsks else { return false }
        if let lastAsk, now.timeIntervalSince(lastAsk) < gap { return false }
        if asks >= applePerYear, let firstAsk, now.timeIntervalSince(firstAsk) < year { return false }
        return true
    }
}

extension View {
    /// Counts the Fin cards the reader reaches, across launches, and asks
    /// for a rating on them as `RatingRequest` plans. `finishedSessions`
    /// grows by one each time a session's end card comes on screen
    /// (`ReelSession.finishedSessions`); `onEndCard` is true while an end
    /// card is on screen.
    func asksForRating(finishedSessions: Int, onEndCard: Bool) -> some View {
        modifier(RatingRequestModifier(finishedSessions: finishedSessions, onEndCard: onEndCard))
    }
}

private struct RatingRequestModifier: ViewModifier {
    let finishedSessions: Int
    let onEndCard: Bool

    @Environment(\.requestReview) private var requestReview
    @AppStorage(RatingRequest.finCardsKey) private var finCards = 0
    @AppStorage(RatingRequest.askCountKey) private var askCount = 0
    @AppStorage(RatingRequest.firstAskKey) private var firstAsk: Double = 0
    @AppStorage(RatingRequest.lastAskKey) private var lastAsk: Double = 0

    private var isDue: Bool {
        onEndCard && RatingRequest.isDue(
            finCards: finCards,
            asks: askCount,
            firstAsk: Self.date(firstAsk),
            lastAsk: Self.date(lastAsk)
        )
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: finishedSessions) {
                // Only the first ask waits for a number of Fin cards.
                guard finCards < RatingRequest.firstFinCard else { return }
                finCards += 1
            }
            .task(id: isDue) {
                guard isDue else { return }
                // Leaving the card before the pause is over (Keep reading)
                // cancels the wait; the next Fin card asks instead.
                do {
                    try await Task.sleep(for: RatingRequest.pause)
                } catch is CancellationError {
                    return
                } catch {
                    print("RatingRequest: the pause before asking failed — \(error)")
                    return
                }
                let now = Date.now.timeIntervalSinceReferenceDate
                if askCount == 0 { firstAsk = now }
                lastAsk = now
                askCount += 1
                requestReview()
            }
    }

    /// A saved time, or nil for never.
    private static func date(_ seconds: Double) -> Date? {
        seconds > 0 ? Date(timeIntervalSinceReferenceDate: seconds) : nil
    }
}
