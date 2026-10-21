//
//  ReviewHTML.swift
//  VILLE
//
//  Turns Letterboxd review HTML into blocks SwiftUI can draw: paragraphs,
//  quotes and list items, each an `AttributedString` with bold, italics and
//  links. Hand-rolled instead of `NSAttributedString(html:)` because that
//  importer spins up WebKit, must run on the main thread, and gives no control
//  over how quotes look.
//
//  Only a handful of tags are understood (p, br, b/strong, i/em, a,
//  blockquote, ul/ol/li). Everything else is ignored, so unknown or unsafe
//  markup never renders.
//

import Foundation
import SwiftUI  // for the `underlineStyle` attribute on links

/// One visual block of a review, in reading order.
enum ReviewBlock: Hashable {
    case paragraph(AttributedString)
    case quote(AttributedString)
    case listItem(marker: String, text: AttributedString)
}

enum ReviewHTML {
    /// Parsed blocks keyed by the HTML itself, so an edited review is re-parsed.
    private static var cache: [String: [ReviewBlock]] = [:]

    static func blocks(for review: Review) -> [ReviewBlock] {
        let html = review.reviewHTML
        if let cached = cache[html] { return cached }
        var builder = BlockBuilder()
        builder.consume(html)
        let blocks = builder.finish()
        cache[html] = blocks
        return blocks
    }

    /// Tag-free text, used to check that a review actually has words in it.
    nonisolated static func plainText(from html: String) -> String {
        let stripped = html.replacingOccurrences(of: "<[^>]*>", with: " ", options: .regularExpression)
        return decodeEntities(stripped)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Entities

    private nonisolated static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "mdash": "—", "ndash": "–", "hellip": "…",
        "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
    ]

    /// Replaces `&amp;`, `&#039;`, `&#x2019;`… with the characters they stand for.
    nonisolated static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }

        var output = ""
        var rest = text[...]
        while let amp = rest.firstIndex(of: "&") {
            output += rest[..<amp]
            let afterAmp = rest[rest.index(after: amp)...]
            if let semi = afterAmp.prefix(10).firstIndex(of: ";"),
               let decoded = decodeEntity(afterAmp[..<semi]) {
                output += decoded
                rest = afterAmp[afterAmp.index(after: semi)...]
            } else {
                output += "&"
                rest = afterAmp
            }
        }
        output += rest
        return output
    }

    private nonisolated static func decodeEntity(_ name: Substring) -> String? {
        if name.hasPrefix("#x") || name.hasPrefix("#X") {
            return UInt32(name.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String($0) }
        }
        if name.hasPrefix("#") {
            return UInt32(name.dropFirst()).flatMap(Unicode.Scalar.init).map { String($0) }
        }
        return namedEntities[String(name)]
    }
}

// MARK: - Builder

/// Walks the HTML once, tracking open tags, and emits a block each time a
/// paragraph, quote or list item ends.
private struct BlockBuilder {
    private struct Run {
        var text: String
        var bold: Bool
        var italic: Bool
        var link: URL?
    }

    private enum ListKind {
        case bullet
        case numbered(Int)
    }

    private var blocks: [ReviewBlock] = []
    private var runs: [Run] = []
    private var boldDepth = 0
    private var italicDepth = 0
    private var quoteDepth = 0
    private var links: [URL?] = []
    private var lists: [ListKind] = []
    private var pendingMarker: String?

    mutating func consume(_ html: String) {
        var rest = html[...]
        while let open = rest.firstIndex(of: "<") {
            appendText(String(rest[..<open]))
            guard let close = rest[open...].firstIndex(of: ">") else {
                // Unclosed "<" — treat the remainder as text.
                rest = rest[open...]
                break
            }
            handleTag(String(rest[rest.index(after: open)..<close]))
            rest = rest[rest.index(after: close)...]
        }
        appendText(String(rest))
    }

    mutating func finish() -> [ReviewBlock] {
        flush()
        return blocks
    }

    // MARK: Tags

    private mutating func handleTag(_ raw: String) {
        let isClosing = raw.hasPrefix("/")
        let body = isClosing ? raw.dropFirst() : raw[...]
        let name = body.prefix { $0.isLetter || $0.isNumber }.lowercased()

        switch (name, isClosing) {
        case ("p", _), ("div", _):
            flush()
        case ("br", false):
            appendLineBreak()
        case ("b", false), ("strong", false):
            boldDepth += 1
        case ("b", true), ("strong", true):
            boldDepth = max(0, boldDepth - 1)
        case ("i", false), ("em", false):
            italicDepth += 1
        case ("i", true), ("em", true):
            italicDepth = max(0, italicDepth - 1)
        case ("a", false):
            links.append(Self.href(in: String(body)))
        case ("a", true):
            _ = links.popLast()
        case ("blockquote", false):
            flush()
            quoteDepth += 1
        case ("blockquote", true):
            flush()
            quoteDepth = max(0, quoteDepth - 1)
        case ("ul", false):
            flush()
            lists.append(.bullet)
        case ("ol", false):
            flush()
            lists.append(.numbered(0))
        case ("ul", true), ("ol", true):
            flush()
            _ = lists.popLast()
        case ("li", false):
            flush()
            pendingMarker = nextListMarker()
        case ("li", true):
            flush()
        default:
            break
        }
    }

    private mutating func nextListMarker() -> String {
        guard case .numbered(let count)? = lists.last else { return "•" }
        lists[lists.count - 1] = .numbered(count + 1)
        return "\(count + 1)."
    }

    private static func href(in tagBody: String) -> URL? {
        guard let match = tagBody.range(of: #"href\s*=\s*["'][^"']*["']"#, options: .regularExpression) else {
            return nil
        }
        let value = tagBody[match]
            .drop { $0 != "\"" && $0 != "'" }
            .dropFirst()
            .dropLast()
        return URL(string: ReviewHTML.decodeEntities(String(value)))
    }

    // MARK: Text

    private var currentLink: URL? { links.last ?? nil }

    private mutating func appendText(_ raw: String) {
        // HTML treats any run of whitespace as a single space.
        var text = raw.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let previous = runs.last?.text ?? "\n"
        if previous.hasSuffix(" ") || previous.hasSuffix("\n"), text.hasPrefix(" ") {
            text.removeFirst()
        }
        guard !text.isEmpty else { return }
        runs.append(Run(
            text: ReviewHTML.decodeEntities(text),
            bold: boldDepth > 0,
            italic: italicDepth > 0,
            link: currentLink
        ))
    }

    private mutating func appendLineBreak() {
        if let last = runs.indices.last, runs[last].text.hasSuffix(" ") {
            runs[last].text.removeLast()
        }
        runs.append(Run(text: "\n", bold: false, italic: false, link: nil))
    }

    // MARK: Blocks

    /// Ends the current block. Empty blocks are skipped but keep a pending
    /// list marker, so `<li><p>text</p></li>` still becomes one list item.
    private mutating func flush() {
        let text = Self.attributed(from: runs)
        runs = []
        guard !text.characters.isEmpty else { return }

        if let marker = pendingMarker {
            blocks.append(.listItem(marker: marker, text: text))
            pendingMarker = nil
        } else if quoteDepth > 0 {
            blocks.append(.quote(text))
        } else {
            blocks.append(.paragraph(text))
        }
    }

    private static func attributed(from runs: [Run]) -> AttributedString {
        var result = AttributedString()
        for run in runs {
            var piece = AttributedString(run.text)
            var intent: InlinePresentationIntent = []
            if run.bold { intent.insert(.stronglyEmphasized) }
            if run.italic { intent.insert(.emphasized) }
            if !intent.isEmpty { piece.inlinePresentationIntent = intent }
            if let link = run.link {
                piece.link = link
                piece.underlineStyle = .single
            }
            result += piece
        }
        return trimmed(result)
    }

    private static func trimmed(_ text: AttributedString) -> AttributedString {
        var text = text
        while let first = text.characters.first, first.isWhitespace {
            text.removeSubrange(text.startIndex..<text.characters.index(after: text.startIndex))
        }
        while let last = text.characters.last, last.isWhitespace {
            text.removeSubrange(text.characters.index(before: text.endIndex)..<text.endIndex)
        }
        return text
    }
}
