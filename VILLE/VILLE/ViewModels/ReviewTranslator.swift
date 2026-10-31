//
//  ReviewTranslator.swift
//  VILLE
//
//  Which reviews are shown translated. Shared by the reel and the full
//  reader, so a review translated on the reel opens translated too.
//  Translations stay in memory until the app quits (like revealed
//  spoilers) and are never saved: they're a way of reading, not content.
//

import Foundation
import Observation
import SwiftUI  // withAnimation
import Translation

@Observable
final class ReviewTranslator {
    /// How the note under a review's dateline reads right now.
    enum State {
        case original
        case translating
        case translated
    }

    /// What reviews are translated into: the iPhone's language.
    let target: Locale.Language

    /// Languages Translation can handle on this iPhone, filled at launch.
    /// Until then no review offers a translation.
    private var supported: Set<Locale.LanguageCode> = []

    /// The translated blocks, with the HTML they came from, so an edited
    /// review isn't shown with an old translation.
    private var translations: [String: (html: String, blocks: [ReviewBlock])] = [:]
    private var showing: Set<String> = []
    private var inFlight: Set<String> = []

    init(target: Locale.Language = ReviewTranslation.deviceLanguage) {
        self.target = target
    }

    func loadSupportedLanguages() async {
        let languages = await LanguageAvailability().supportedLanguages
        supported = Set(languages.compactMap(\.languageCode))
    }

    // MARK: Reading

    /// The language to offer a translation from, or nil when the review is
    /// already in the iPhone's language, the language is unclear, or
    /// Translation can't do the pair.
    func sourceLanguage(for review: Review) -> Locale.Language? {
        guard let target = target.languageCode, supported.contains(target),
              let source = ReviewTranslation.language(of: review.reviewHTML),
              let code = source.languageCode, code != target, supported.contains(code)
        else { return nil }
        return source
    }

    /// The blocks to draw: translated when the reader asked for it.
    func blocks(for review: Review) -> [ReviewBlock] {
        if showing.contains(review.id), let blocks = translatedBlocks(for: review) {
            return blocks
        }
        return ReviewHTML.blocks(for: review)
    }

    func state(for review: Review) -> State {
        if inFlight.contains(review.id) { return .translating }
        if showing.contains(review.id), translatedBlocks(for: review) != nil { return .translated }
        return .original
    }

    /// True when the translation is already here, so it can be shown again
    /// without asking Translation.
    func hasTranslation(for review: Review) -> Bool {
        translatedBlocks(for: review) != nil
    }

    // MARK: Switching

    func showTranslation(of review: Review) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            _ = showing.insert(review.id)
        }
    }

    func showOriginal(of review: Review) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            _ = showing.remove(review.id)
        }
    }

    /// Translates the review with the session `.translationTask` hands
    /// over, then shows it. Does nothing if it's already translated or on
    /// its way.
    func translate(_ review: Review, using session: TranslationSession) async {
        let id = review.id
        let html = review.reviewHTML
        guard !hasTranslation(for: review), !inFlight.contains(id) else { return }

        inFlight.insert(id)
        do {
            let blocks = try await ReviewTranslation.translate(ReviewHTML.blocks(for: review), using: session)
            translations[id] = (html, blocks)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                inFlight.remove(id)
                showing.insert(id)
            }
        } catch {
            // Also lands here when the reader declines to download the
            // languages, or scrolls away mid-translation.
            print("ReviewTranslator: could not translate review \(id) into \(target.minimalIdentifier) — \(error)")
            inFlight.remove(id)
        }
    }

    // MARK: Private

    private func translatedBlocks(for review: Review) -> [ReviewBlock]? {
        guard let translation = translations[review.id], translation.html == review.reviewHTML else { return nil }
        return translation.blocks
    }
}
