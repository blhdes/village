//
//  LetterboxdLink.swift
//  VILLE
//
//  Links people paste to add a member, beyond a plain username. The
//  Letterboxd app shares profiles and reviews as boxd.it short links
//  ("https://boxd.it/dE0n"): VILLE resolves one with a single HEAD request
//  to boxd.it and reads only where it points (the redirect's Location),
//  never following it, so no Letterboxd page is fetched (ToS 6.11). The
//  address it points to then goes through `RSSService.normalizeUsername`.
//  A link into one of Letterboxd's own sections (a film page, a journal
//  story) leads to no member and gets its own message.
//

import Foundation

enum LetterboxdLinkError: LocalizedError {
    /// boxd.it didn't answer, or didn't point to letterboxd.com.
    case unresolved
    /// A film page, a journal story…: nobody to follow there.
    case notAMember

    var errorDescription: String? {
        switch self {
        case .unresolved: String(localized: "Couldn't open that link. Try the member's username instead.")
        case .notAMember: String(localized: "That link isn't to a member's profile or one of their reviews.")
        }
    }
}

nonisolated enum LetterboxdLink {
    /// Letterboxd's own top-level sections. Each is a path of its own on
    /// letterboxd.com, so no member can be called that.
    private static let sections: Set<String> = [
        "film", "films", "list", "lists", "journal", "members", "people", "search", "tag",
        "actor", "director", "writer", "producer", "studio", "crew", "activity", "settings",
        "pro", "patron",
    ]

    /// What to read a username from: a boxd.it short link turned into the
    /// letterboxd.com address it points to; anything else as it was typed.
    static func expand(_ input: String) async throws -> String {
        guard let shortLink = shortLink(in: input) else { return input }
        return try await destination(of: shortLink)
    }

    /// Throws `.notAMember` for a letterboxd.com address inside one of
    /// Letterboxd's own sections, like a film page.
    static func requireMember(_ address: String) throws {
        let lowered = address.lowercased()
        guard let range = lowered.range(of: "letterboxd.com/") else { return }
        let first = lowered[range.upperBound...].prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        if sections.contains(String(first)) {
            throw LetterboxdLinkError.notAMember
        }
    }

    /// "boxd.it/dE0n" with or without its scheme, as https. The code after
    /// the slash keeps its case: boxd.it codes are case-sensitive.
    private static func shortLink(in input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") { text = "https://" + text }
        guard var components = URLComponents(string: text),
              components.host?.lowercased() == "boxd.it",
              components.path.count > 1
        else { return nil }
        components.scheme = "https"
        return components.url
    }

    /// One HEAD request to boxd.it, read for its redirect only.
    private static func destination(of shortLink: URL) async throws -> String {
        var request = URLRequest(url: shortLink)
        request.httpMethod = "HEAD"

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request, delegate: StopAtRedirect())
        } catch {
            print("LetterboxdLink: couldn't reach \(shortLink): \(error)")
            throw LetterboxdLinkError.unresolved
        }

        guard let http = response as? HTTPURLResponse,
              (300..<400).contains(http.statusCode),
              let location = http.value(forHTTPHeaderField: "Location"),
              let address = URL(string: location, relativeTo: shortLink)?.absoluteURL,
              let host = address.host()?.lowercased(),
              host == "letterboxd.com" || host == "www.letterboxd.com"
        else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("LetterboxdLink: \(shortLink) didn't point to letterboxd.com (HTTP \(status))")
            throw LetterboxdLinkError.unresolved
        }
        return address.absoluteString
    }
}

/// Keeps URLSession from following the short link: VILLE only reads where
/// it points, it never opens the page. The completion-handler form: the
/// `async` one crashes the Swift 6 compiler in Xcode 27.2.
private nonisolated final class StopAtRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
