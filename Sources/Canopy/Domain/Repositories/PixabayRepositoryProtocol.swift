import Foundation

protocol PixabayRepositoryProtocol: Sendable {
    func search(
        query: String,
        category: String?,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse
}
