//
//  RSSService.swift
//  VILLE
//
//  Fetches a member's public Letterboxd RSS feed — the access route Letterboxd
//  offers in place of its private API — and keeps only written reviews.
//  Lists and plain "watched" diary entries are dropped so the app stays
//  pure text.
//
//  Never reads Letterboxd HTML pages: scraping is forbidden by ToS 6.11.
//

import Foundation

// MARK: - Result types

/// A review as parsed from RSS, before it becomes a SwiftData `Review`.
struct ParsedReview: Sendable {
    let id: String
    let username: String
    let authorName: String
    let link: String
    let publishedAt: Date
    let watchedOn: Date?
    let filmTitle: String
    let filmYear: Int?
    let tmdbID: Int?
    let rating: Double?
    let liked: Bool
    let isRewatch: Bool
    let containsSpoilers: Bool
    let reviewHTML: String
}

struct UserFeed: Sendable {
    /// Display name from the feed, or nil if the feed had nothing to read it from.
    let displayName: String?
    let reviews: [ParsedReview]
}

// MARK: - Errors

enum RSSError: LocalizedError {
    case invalidUsername(String)
    case userNotFound(String)
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidUsername(let input): "“\(input)” isn't a valid Letterboxd username."
        case .userNotFound(let username): "No Letterboxd member called “\(username)”."
        case .badResponse(let code): "Letterboxd returned an error (HTTP \(code))."
        }
    }
}

// MARK: - Service

struct RSSService {

    /// Fetch and parse one member's feed. Throws so callers decide how to
    /// report failures (one bad member must not break the whole refresh).
    func fetchUserFeed(username: String) async throws -> UserFeed {
        guard let url = URL(string: "https://letterboxd.com/\(username)/rss/") else {
            throw RSSError.invalidUsername(username)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw RSSError.userNotFound(username) }
            guard (200..<300).contains(http.statusCode) else {
                throw RSSError.badResponse(http.statusCode)
            }
        }

        let delegate = RSSParserDelegate(username: username)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        guard parser.parse() else {
            throw parser.parserError ?? RSSError.badResponse(0)
        }
        return UserFeed(displayName: delegate.displayName, reviews: delegate.reviews)
    }

    /// Turns what the user typed — "Dave", "@dave", or a profile link — into
    /// a lowercase handle. Returns nil when it can't be a Letterboxd username.
    static func normalizeUsername(_ input: String) -> String? {
        var handle = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let range = handle.range(of: "letterboxd.com/") {
            handle = String(handle[range.upperBound...])
            handle = String(handle.prefix { $0 != "/" && $0 != "?" })
        }
        if handle.hasPrefix("@") { handle.removeFirst() }

        guard !handle.isEmpty,
              handle.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") })
        else { return nil }
        return handle
    }
}

// MARK: - XML delegate

/// SAX-style parser that collects `<item>` elements, keeping only reviews.
/// Nonisolated because `XMLParserDelegate` callbacks are nonisolated.
private nonisolated final class RSSParserDelegate: NSObject, XMLParserDelegate {
    let username: String
    private(set) var reviews: [ParsedReview] = []
    private var channelTitle: String?
    private var firstCreator: String?

    private var currentItem: [String: String] = [:]
    private var buffer = ""
    private var insideItem = false

    init(username: String) {
        self.username = username
    }

    /// Prefer the author's name on an item; fall back to the channel title
    /// ("Letterboxd - Dave Vis") for members whose feed has no items.
    var displayName: String? {
        if let firstCreator, !firstCreator.isEmpty { return firstCreator }
        guard let channelTitle else { return nil }
        let name = channelTitle.replacingOccurrences(of: "Letterboxd - ", with: "")
        return name.isEmpty ? nil : name
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        buffer = ""
        if elementName == "item" {
            insideItem = true
            currentItem = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    // Letterboxd wraps the HTML description in CDATA.
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let text = String(data: CDATABlock, encoding: .utf8) else { return }
        buffer += text
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = ""

        guard insideItem else {
            if elementName == "title", channelTitle == nil { channelTitle = text }
            return
        }

        guard elementName == "item" else {
            currentItem[elementName] = text
            return
        }

        insideItem = false
        if firstCreator == nil { firstCreator = currentItem["dc:creator"] }
        if let review = makeReview(from: currentItem) {
            reviews.append(review)
        }
    }

    // MARK: Map item → ParsedReview

    private func makeReview(from item: [String: String]) -> ParsedReview? {
        // Letterboxd marks each item's kind in the guid:
        // letterboxd-review-…, letterboxd-watch-…, letterboxd-list-…
        guard let guid = item["guid"], guid.hasPrefix("letterboxd-review-"),
              let link = item["link"]
        else { return nil }

        var html = item["description"] ?? ""
        // The first paragraph is always the film poster from Letterboxd's CDN.
        html = html.replacingOccurrences(
            of: #"^\s*<p>\s*<img[^>]*>\s*</p>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Spoiler reviews open with an italic warning paragraph.
        let spoilerPattern = #"<p>\s*<(em|i)>\s*This review may contain spoilers\.?\s*</(em|i)>\s*</p>"#
        let markedInBody = html.range(of: spoilerPattern, options: [.regularExpression, .caseInsensitive]) != nil
        if markedInBody {
            html = html.replacingOccurrences(of: spoilerPattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
        let title = item["title"] ?? ""
        let containsSpoilers = markedInBody || title.localizedCaseInsensitiveContains("(contains spoilers)")

        html = html.trimmingCharacters(in: .whitespacesAndNewlines)
        // A "review" with no words left is just a diary entry — skip it.
        guard !ReviewHTML.plainText(from: html).isEmpty else { return nil }

        let pubDate = item["pubDate"] ?? ""
        return ParsedReview(
            id: guid,
            username: username,
            authorName: item["dc:creator"] ?? username,
            link: link,
            publishedAt: Self.rfc822.date(from: pubDate) ?? .distantPast,
            watchedOn: item["letterboxd:watchedDate"].flatMap { Self.dayFormatter.date(from: $0) },
            filmTitle: item["letterboxd:filmTitle"] ?? title,
            filmYear: item["letterboxd:filmYear"].flatMap { Int($0) },
            tmdbID: item["tmdb:movieId"].flatMap { Int($0) },
            rating: item["letterboxd:memberRating"].flatMap { Double($0) },
            liked: item["letterboxd:memberLike"] == "Yes",
            isRewatch: item["letterboxd:rewatch"] == "Yes",
            containsSpoilers: containsSpoilers,
            reviewHTML: html
        )
    }

    // MARK: Dates

    /// "Thu, 15 Oct 2026 03:23:56 +1300"
    private static let rfc822: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    /// "2026-10-14"
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
