//
//  RSSService.swift
//  VILLE
//
//  Fetches Letterboxd public RSS feeds and parses them into `Review` models.
//
//  Ported from `services/feed.ts` (RN project). Uses Foundation's `XMLParser`
//  (SAX-style, zero dependencies). The parser is wrapped in a small delegate
//  that accumulates items and returns them once parsing finishes.
//
//  Threading: all public APIs are `async` and safe to call from anywhere.
//  Network work happens on URLSession's default queue; parsing runs on the
//  current actor (cheap for typical RSS sizes).
//

import Foundation

// MARK: - Result type

/// Plain-old struct representing a parsed RSS item, **before** it's turned
/// into a SwiftData `Review`. Keeps the parser decoupled from persistence.
struct ParsedReview: Sendable {
    let id: String
    let username: String
    let title: String
    let link: String
    let pubDateRaw: String
    let publishedAt: Date
    let creator: String
    let reviewHTML: String
    let rating: String
    let movieTitle: String
    let kind: ReviewKind
}

// MARK: - Errors

enum RSSError: Error, LocalizedError {
    case invalidURL(String)
    case badResponse(Int)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL(let u): "Invalid RSS URL: \(u)"
        case .badResponse(let code): "Letterboxd returned HTTP \(code)"
        case .parsingFailed: "Could not parse the RSS feed"
        }
    }
}

// MARK: - Service

/// Fetches and parses Letterboxd user RSS feeds.
///
/// Stateless by design — no in-memory cache (SwiftData is the cache).
/// If we want a 5-minute soft cache later, wrap this in an actor.
struct RSSService {

    // MARK: Public API

    /// Fetch a single user's feed. Returns an empty array on network failure
    /// (mirrors the RN project's "fail soft" behaviour so one bad user
    /// doesn't break the whole feed).
    func fetchUserFeed(username: String) async -> [ParsedReview] {
        guard let url = URL(string: "https://letterboxd.com/\(username)/rss/") else {
            print("RSSService: invalid username \(username)")
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("RSSService: \(username) returned HTTP \(http.statusCode)")
                return []
            }
            return parse(data: data, username: username)
        } catch {
            print("RSSService: failed to fetch \(username): \(error)")
            return []
        }
    }

    /// Fetch multiple users in parallel and return a merged, date-descending list.
    /// Matches `fetchFeed()` in `services/feed.ts`.
    func fetchFeed(usernames: [String]) async -> [ParsedReview] {
        guard !usernames.isEmpty else { return [] }

        let all = await withTaskGroup(of: [ParsedReview].self) { group in
            for username in usernames {
                group.addTask { await fetchUserFeed(username: username) }
            }
            var merged: [ParsedReview] = []
            for await batch in group { merged.append(contentsOf: batch) }
            return merged
        }

        return all.sorted { $0.publishedAt > $1.publishedAt }
    }

    // MARK: Parsing

    private func parse(data: Data, username: String) -> [ParsedReview] {
        let delegate = RSSParserDelegate(username: username)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        parser.parse()
        return delegate.items
    }
}

// MARK: - XML delegate

/// SAX-style parser that collects `<item>` elements from a Letterboxd RSS feed.
/// Keeps per-item state in a scratch dictionary; commits to `items` on `</item>`.
private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    let username: String
    private(set) var items: [ParsedReview] = []

    private var currentElement: String = ""
    private var currentItem: [String: String] = [:]
    private var buffer: String = ""
    private var insideItem = false

    init(username: String) {
        self.username = username
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        buffer = ""
        if elementName == "item" {
            insideItem = true
            currentItem = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        buffer += string
    }

    // CDATA sections (Letterboxd wraps HTML descriptions in CDATA).
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard insideItem, let s = String(data: CDATABlock, encoding: .utf8) else { return }
        buffer += s
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if insideItem && elementName != "item" {
            // Trim and stash the accumulated text against the tag name.
            currentItem[elementName] = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if elementName == "item" {
            if let parsed = makeReview(from: currentItem) {
                items.append(parsed)
            }
            insideItem = false
            currentItem = [:]
        }

        buffer = ""
    }

    // MARK: Map dictionary → ParsedReview

    private func makeReview(from item: [String: String]) -> ParsedReview? {
        let link = item["link"] ?? ""
        // Skip "list" activity entries (matches RN project).
        if link.contains("/list/") { return nil }

        let title = item["title"] ?? ""
        let rawDescription = item["description"] ?? ""
        let pubDateRaw = item["pubDate"] ?? ""
        // `dc:creator` arrives un-namespaced because we disabled namespace processing.
        let creator = item["dc:creator"] ?? username

        let cleaned = cleanDescription(rawDescription)
        let plain = cleaned.strippingHTMLTags()
        let isWatch = plain.isEmpty || plain.hasPrefix("Watched on")

        return ParsedReview(
            id: "\(username)-\(link)",
            username: username,
            title: title,
            link: link,
            pubDateRaw: pubDateRaw,
            publishedAt: Self.parseRFC822(pubDateRaw) ?? .distantPast,
            creator: creator,
            reviewHTML: isWatch ? "" : cleaned,
            rating: Self.extractRating(from: title),
            movieTitle: Self.extractMovieTitle(from: title),
            kind: isWatch ? .watch : .review
        )
    }

    // MARK: Helpers (mirror services/feed.ts)

    /// Extract "★★★½" from a title ending in " - ★★★½".
    static func extractRating(from title: String) -> String {
        // Match trailing " - " followed by any run of ★ and ½ characters.
        guard let match = title.range(
            of: #" - ([★½]+)$"#,
            options: .regularExpression
        ) else { return "" }
        let slice = title[match]
        // Strip the leading " - " prefix.
        return slice.replacingOccurrences(of: " - ", with: "")
    }

    /// Remove year + optional rating suffix: "Movie, 1984 - ★★★½" → "Movie".
    static func extractMovieTitle(from title: String) -> String {
        let pattern = #",\s*\d{4}\s*(-\s*[★½]+)?$"#
        let cleaned = title.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    /// Drop the poster `<img>` block and any risky script/style/form tags.
    /// Intentionally lenient — preserves bold, italics, blockquotes, links, images.
    private func cleanDescription(_ html: String) -> String {
        guard !html.isEmpty else { return "" }
        let posterStripped = html.replacingOccurrences(
            of: #"<p>\s*<img[^>]*>\s*</p>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        let sanitised = posterStripped.replacingOccurrences(
            of: #"</?(?:script|style|form|input|textarea|select|button)\b[^>]*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return sanitised.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Date parsing

    /// Parses RFC 822 dates (e.g. "Sun, 19 Apr 2026 08:14:23 +0000") — the format
    /// Letterboxd RSS uses. Returns nil on failure; caller falls back to .distantPast.
    private static let rfc822Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    static func parseRFC822(_ s: String) -> Date? {
        rfc822Formatter.date(from: s)
    }
}
