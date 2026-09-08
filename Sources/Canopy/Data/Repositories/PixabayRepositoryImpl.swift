import Foundation

final class PixabayRepositoryImpl: PixabayRepositoryProtocol {
    private let client: PixabayClient
    private let cache: SearchResultsCache

    init(client: PixabayClient = PixabayClient(), cache: SearchResultsCache = .shared) {
        self.client = client
        self.cache = cache
    }

    func search(
        query: String,
        category: String?,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse {
        if let cached = await cache.value(query: query, category: category, page: page) {
            return cached
        }
        let response = try await client.search(
            query: query,
            category: category,
            page: page,
            perPage: perPage,
            apiKey: apiKey
        )
        await cache.store(response, query: query, category: category, page: page)
        return response
    }
}
