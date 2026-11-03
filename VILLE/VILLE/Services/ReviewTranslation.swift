//
//  ReviewTranslation.swift
//  VILLE
//
//  Finds out which language a review is written in and translates its
//  blocks into the reader's language. Both happen on the device: language
//  detection with NaturalLanguage, translation with Apple's Translation
//  framework (Apple Intelligence's models when the iPhone has them, the
//  downloadable Translate languages otherwise). Nothing is sent or saved.
//
//  Each paragraph, quote and list item is translated on its own, so the
//  review keeps its shape. From iOS 26.4 the translation also keeps the
//  italics, bold and links inside them; before that it comes back as
//  plain text.
//

import Foundation
import NaturalLanguage
import SwiftUI  // for the `underlineStyle` attribute on links
import Translation

enum ReviewTranslation {
    /// The reader's languages, most preferred first. That's the iPhone's
    /// list, unless a language was picked for VILLE alone (iOS Settings →
    /// VILLE → Language, reached from VILLE's Settings): iOS then puts that
    /// one first for this app. Not `Locale.current`, which only knows the
    /// languages VILLE's interface comes in: a Korean iPhone would get
    /// English there, but its reviews should still turn into Korean.
    static var readerLanguages: [Locale.Language] {
        Locale.preferredLanguages.map { Locale.Language(identifier: $0) }
    }

    /// Below this, the detector is guessing (very short reviews, mixed
    /// languages), and offering to translate "wow." would be odd.
    private static let minimumConfidence = 0.6

    /// Detected languages keyed by the review's HTML, so an edited review is
    /// checked again. A stored nil means "checked, unsure".
    private static var detected: [String: Locale.Language?] = [:]

    /// The language the review is written in, or nil when unsure.
    static func language(of html: String) -> Locale.Language? {
        if let cached = detected[html] { return cached }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(ReviewHTML.plainText(from: html))
        let best = recognizer.languageHypotheses(withMaximum: 1).max { $0.value < $1.value }

        var language: Locale.Language?
        if let best, best.value >= minimumConfidence {
            language = Locale.Language(identifier: best.key.rawValue)
        }
        detected[html] = language
        return language
    }

    /// The review's blocks in the session's target language, in the same
    /// order and with the same kinds (paragraph, quote, list item).
    static func translate(_ blocks: [ReviewBlock], using session: TranslationSession) async throws -> [ReviewBlock] {
        let requests = blocks.enumerated().map { index, block in
            request(for: block.text, id: String(index))
        }
        let responses = try await session.translations(from: requests)

        var translated: [Int: AttributedString] = [:]
        for response in responses {
            guard let index = response.clientIdentifier.flatMap(Int.init) else { continue }
            translated[index] = text(of: response)
        }
        // A block Translation skipped keeps its original words.
        return blocks.enumerated().map { index, block in
            block.replacingText(with: translated[index] ?? block.text)
        }
    }

    // MARK: Private

    private static func request(for text: AttributedString, id: String) -> TranslationSession.Request {
        if #available(iOS 26.4, *) {
            return TranslationSession.Request(sourceText: text, clientIdentifier: id)
        }
        return TranslationSession.Request(sourceText: String(text.characters), clientIdentifier: id)
    }

    private static func text(of response: TranslationSession.Response) -> AttributedString {
        guard #available(iOS 26.4, *), var text = response.attributedTargetText else {
            return AttributedString(response.targetText)
        }
        // Links keep their underline, as in the original.
        let linkRanges = text.runs.filter { $0.link != nil }.map(\.range)
        for range in linkRanges {
            text[range].underlineStyle = .single
        }
        return text
    }
}

private extension ReviewBlock {
    var text: AttributedString {
        switch self {
        case .paragraph(let text), .quote(let text), .listItem(_, let text):
            text
        }
    }

    /// The same kind of block (and list marker) with other words in it.
    func replacingText(with text: AttributedString) -> ReviewBlock {
        switch self {
        case .paragraph: .paragraph(text)
        case .quote: .quote(text)
        case .listItem(let marker, _): .listItem(marker: marker, text: text)
        }
    }
}
