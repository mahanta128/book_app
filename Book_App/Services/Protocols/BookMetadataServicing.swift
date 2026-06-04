import Foundation

protocol BookMetadataServicing: Sendable {
    func resolve(candidate: SpineCandidate) async throws -> BookIdentity?
}
