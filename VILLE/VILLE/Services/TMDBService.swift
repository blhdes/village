//
//  TMDBService.swift
//  VILLE
//
//  Looks up a film's posters and backdrops on TMDB using the `tmdb:movieId`
//  Letterboxd puts in every RSS item — no title search needed. One request
//  per film brings the official art and the whole image gallery, in every
//  language.
//
//  TMDB's terms require the attribution shown in Settings.
//

import Foundation

struct FilmArt: Sendable {
    /// Official poster first, then alternatives: other countries' releases
    /// and posters without text.
    let posterPaths: [String]
    /// Official backdrop first, then other backdrops without text.
    let backdropPaths: [String]
}

enum TMDBError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "TMDB API key is missing. Add it to Secrets.swift."
        case .invalidURL: "Could not build the TMDB request URL."
        case .badResponse(let code): "TMDB returned an error (HTTP \(code))."
        }
    }
}

struct TMDBService {
    private static let apiBase = URL(string: "https://api.themoviedb.org/3")!
    private static let imageBase = "https://image.tmdb.org/t/p"

    /// Gallery limits. At most two posters per language, so other
    /// countries' posters get a turn next to the English ones.
    private static let maxPosters = 12
    private static let postersPerLanguage = 2
    private static let maxBackdrops = 10

    /// Returns empty art when TMDB doesn't know the film.
    func art(forMovieID id: Int) async throws -> FilmArt {
        guard !Secrets.tmdbAPIKey.isEmpty else { throw TMDBError.missingAPIKey }

        var components = URLComponents(
            url: Self.apiBase.appending(path: "movie/\(id)"),
            resolvingAgainstBaseURL: false
        )
        // No `language` parameter: the appended images then come in every
        // language, not just English.
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey),
            URLQueryItem(name: "append_to_response", value: "images"),
        ]
        guard let url = components?.url else { throw TMDBError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { return FilmArt(posterPaths: [], backdropPaths: []) }
            guard (200..<300).contains(http.statusCode) else {
                throw TMDBError.badResponse(http.statusCode)
            }
        }

        let movie = try JSONDecoder().decode(MovieArt.self, from: data)
        return FilmArt(
            posterPaths: Self.posters(official: movie.posterPath, from: movie.images?.posters ?? []),
            backdropPaths: Self.backdrops(official: movie.backdropPath, from: movie.images?.backdrops ?? [])
        )
    }

    /// Full image URL for a TMDB path, e.g. size "w342" for posters.
    static func imageURL(path: String?, size: String) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBase)/\(size)\(path)")
    }

    // MARK: Galleries

    /// The official poster, then the best-rated others, two per language at most.
    private static func posters(official: String?, from images: [TMDBImage]) -> [String] {
        var paths = official.map { [$0] } ?? []
        var perLanguage: [String: Int] = [:]
        if let official, let image = images.first(where: { $0.filePath == official }) {
            perLanguage[image.languageKey, default: 0] += 1
        }

        for image in images.sorted(by: { $0.voteAverage > $1.voteAverage }) {
            guard paths.count < maxPosters else { break }
            guard !paths.contains(image.filePath),
                  perLanguage[image.languageKey, default: 0] < postersPerLanguage else { continue }
            paths.append(image.filePath)
            perLanguage[image.languageKey, default: 0] += 1
        }
        return paths
    }

    /// The official backdrop, then others without text, in TMDB's order.
    private static func backdrops(official: String?, from images: [TMDBImage]) -> [String] {
        var paths = official.map { [$0] } ?? []
        for image in images where image.language == nil && !paths.contains(image.filePath) {
            guard paths.count < maxBackdrops else { break }
            paths.append(image.filePath)
        }
        return paths
    }
}

/// The fields we need from `GET /movie/{id}?append_to_response=images`.
private nonisolated struct MovieArt: Decodable {
    let posterPath: String?
    let backdropPath: String?
    let images: Gallery?

    struct Gallery: Decodable {
        let posters: [TMDBImage]?
        let backdrops: [TMDBImage]?
    }

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case images
    }
}

private nonisolated struct TMDBImage: Decodable {
    let filePath: String
    /// Language of the text on the image; nil when it has none.
    let language: String?
    let voteAverage: Double

    /// Groups textless images together when counting per language.
    var languageKey: String { language ?? "none" }

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case language = "iso_639_1"
        case voteAverage = "vote_average"
    }
}
