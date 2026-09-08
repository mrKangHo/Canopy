import Foundation

protocol FetchVideosUseCaseProtocol: Sendable {
    func search(
        query: String,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse

    func fetchCategory(
        category: String,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse
}

final class FetchVideosUseCase: FetchVideosUseCaseProtocol {
    private let repository: PixabayRepositoryProtocol

    init(repository: PixabayRepositoryProtocol) {
        self.repository = repository
    }

    func search(
        query: String,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse {
        try await repository.search(
            query: query,
            category: nil,
            page: page,
            perPage: perPage,
            apiKey: apiKey
        )
    }

    func fetchCategory(
        category: String,
        page: Int,
        perPage: Int,
        apiKey: String
    ) async throws -> PixabaySearchResponse {
        try await repository.search(
            query: "",
            category: category,
            page: page,
            perPage: perPage,
            apiKey: apiKey
        )
    }
}
