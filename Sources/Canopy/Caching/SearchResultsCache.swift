import Foundation

/// Pixabay's API terms require search results to be cached for 24h rather than
/// re-fetched on every request. A simple in-memory TTL cache keyed by the
/// query + category + page satisfies that and doubles as free rate-limit
/// hygiene — each page is cached independently.
actor SearchResultsCache {
    private struct Entry {
        let response: PixabaySearchResponse
        let storedAt: Date
    }

    static let shared = SearchResultsCache()

    private let ttl: TimeInterval = 24 * 60 * 60
    private var entries: [String: Entry] = [:]

    private func key(query: String, category: String?, page: Int) -> String {
        "\(query.lowercased())|\(category?.lowercased() ?? "")|\(page)"
    }

    func value(query: String, category: String?, page: Int) -> PixabaySearchResponse? {
        let k = key(query: query, category: category, page: page)
        guard let entry = entries[k] else { return nil }
        guard Date().timeIntervalSince(entry.storedAt) < ttl else {
            entries[k] = nil
            return nil
        }
        return entry.response
    }

    func store(_ response: PixabaySearchResponse, query: String, category: String?, page: Int) {
        entries[key(query: query, category: category, page: page)] = Entry(response: response, storedAt: Date())
    }
}
