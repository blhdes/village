//
//  FilmArtLoader.swift
//  VILLE
//
//  Fills in TMDB poster and backdrop paths for saved reviews that don't have
//  them yet. Asks TMDB once per film: art already known from another review
//  of the same film is reused without a request.
//
//  Writes into the reviews but doesn't save — the caller owns the save.
//

import Foundation
import SwiftData

struct FilmArtLoader {
    private let tmdb: TMDBService

    /// Concurrent TMDB requests per batch — keeps well under TMDB's rate limit.
    private let batchSize = 6

    init(tmdb: TMDBService = TMDBService()) {
        self.tmdb = tmdb
    }

    /// Throws only if the saved reviews can't be read. A failed lookup for a
    /// single film is logged and left for the next launch to retry.
    func fillMissingArt(in context: ModelContext) async throws {
        let all = try context.fetch(FetchDescriptor<Review>())

        var known: [Int: FilmArt] = [:]
        for review in all where review.artFetched {
            guard let id = review.tmdbID else { continue }
            known[id] = FilmArt(posterPath: review.posterPath, backdropPath: review.backdropPath)
        }

        let missingIDs = all.filter { !$0.artFetched }.compactMap(\.tmdbID)
        let idsToFetch = Array(Set(missingIDs).subtracting(known.keys))

        batches: for start in stride(from: 0, to: idsToFetch.count, by: batchSize) {
            let batch = idsToFetch[start..<min(start + batchSize, idsToFetch.count)]

            for (id, result) in await fetchArt(for: batch) {
                switch result {
                case .success(let art):
                    known[id] = art
                case .failure(TMDBError.missingAPIKey):
                    print("FilmArtLoader: \(TMDBError.missingAPIKey.localizedDescription)")
                    break batches
                case .failure(let error):
                    // Left un-fetched so the next launch retries.
                    print("FilmArtLoader: TMDB lookup failed for movie \(id) — \(error)")
                }
            }
        }

        // Read again after the waits above: reviews may have been deleted (a
        // member removed) or saved (a member added) while TMDB answered.
        let missing = try context.fetch(FetchDescriptor<Review>(predicate: #Predicate { !$0.artFetched }))
        for review in missing {
            guard let id = review.tmdbID, let art = known[id] else { continue }
            review.posterPath = art.posterPath
            review.backdropPath = art.backdropPath
            review.artFetched = true
        }
    }

    /// Looks up one batch of films in parallel.
    private func fetchArt(for ids: ArraySlice<Int>) async -> [(Int, Result<FilmArt, Error>)] {
        let tmdb = self.tmdb
        return await withTaskGroup(of: (Int, Result<FilmArt, Error>).self) { group in
            for id in ids {
                group.addTask {
                    do {
                        return (id, .success(try await tmdb.art(forMovieID: id)))
                    } catch {
                        return (id, .failure(error))
                    }
                }
            }
            var collected: [(Int, Result<FilmArt, Error>)] = []
            for await result in group { collected.append(result) }
            return collected
        }
    }
}
