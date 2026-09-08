import Foundation

enum PixabayError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return String(localized: "Pixabay API key is not set. Add your key in Settings.")
        case .invalidResponse:
            return String(localized: "Pixabay returned an unexpected response.")
        case .http(let code):
            return String(localized: "Pixabay request failed (HTTP \(code)).")
        }
    }
}

/// Stateless networking client for the Pixabay Video API.
/// Takes the API key as a parameter rather than reading it itself, so callers
/// (and tests) control key sourcing — the real app sources it from `APIKeyStore`.
struct PixabayClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// `page`/`perPage` map directly to Pixabay's pagination params. Note
    /// Pixabay caps `totalHits` (the actually-paginatable count) at 500
    /// regardless of how many results technically match.
    func search(
        query: String,
        category: String? = nil,
        page: Int = 1,
        perPage: Int = 30,
        apiKey: String
    ) async throws -> PixabaySearchResponse {
        guard !apiKey.isEmpty else { throw PixabayError.missingAPIKey }

        var components = URLComponents(string: "https://pixabay.com/api/videos/")!
        var items = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        if !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }
        if let category, !category.isEmpty {
            items.append(URLQueryItem(name: "category", value: category))
        }
        components.queryItems = items

        guard let url = components.url else { throw PixabayError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw PixabayError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw PixabayError.http(http.statusCode) }

        return try JSONDecoder().decode(PixabaySearchResponse.self, from: data)
    }
}
