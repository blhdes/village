//
//  ReviewLength.swift
//  VILLE
//
//  How long a review is, in words, and where "very short" ends. Settings →
//  Reading can leave very short reviews (one-liners like "Banger" or
//  "absolute cinema") out of the feed.
//
//  NaturalLanguage counts the words, so languages written without spaces
//  (Japanese, Chinese) count fairly. Each review is counted once, off the
//  main thread, as `RSSService` reads it, and the count is saved on the
//  `Review`.
//

import Foundation
import NaturalLanguage

nonisolated enum ReviewLength {
    /// A review under this many words is very short. Measured on 1,631
    /// reviews from 42 members' feeds (2026-11-02): under 10 words is
    /// almost only one-liners (9% of them); from about 15, short but real
    /// opinions start.
    static let shortLimit = 10

    /// Words in a review's plain text (`ReviewHTML.plainText(from:)`).
    static func words(in text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).count
    }
}
