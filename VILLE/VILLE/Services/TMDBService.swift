//
//  TMDBService.swift
//  VILLE
//
//  Looks up a film's poster and backdrop on TMDB using the `tmdb:movieId`
//  Letterboxd puts in every RSS item — no title search needed.
//
//  TMDB's terms require the attribution shown in Settings.
//

import Foundation

struct FilmArt: Sendable {
    let posterPath: String?
    let backdropPath: String?
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

    /// Returns empty art (both paths nil) when TMDB doesn't know the film.
    func art(forMovieID id: Int) async throws -> FilmArt {
        guard !Secrets.tmdbAPIKey.isEmpty else { throw TMDBError.missingAPIKey }

        var components = URLComponents(
            url: Self.apiBase.appending(path: "movie/\(id)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey)]
        guard let url = components?.url else { throw TMDBError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { return FilmArt(posterPath: nil, backdropPath: nil) }
            guard (200..<300).contains(http.statusCode) else {
                throw TMDBError.badResponse(http.statusCode)
            }
        }

        let images = try JSONDecoder().decode(MovieImages.self, from: data)
        return FilmArt(posterPath: images.posterPath, backdropPath: images.backdropPath)
    }

    /// Full image URL for a TMDB path, e.g. size "w342" for posters.
    static func imageURL(path: String?, size: String) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBase)/\(size)\(path)")
    }
}

/// The two fields we need from `GET /movie/{id}`.
private nonisolated struct MovieImages: Decodable {
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}
