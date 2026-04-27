//
//  NetModelsTests.swift
//  WordbookTests
//
//  Tests for the generic NetModelsReducer.
//

import XCTest
import ComposableArchitecture
import FunNetCore
import FunNetTCA
@testable import Wordbook

@MainActor
final class NetModelsTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a `NetCallReducer.State` whose firing func is `NetCallReducer.mockFire(...)`.
    private func makeCallState(
        data: Data? = nil,
        error: Error? = nil,
        endpoint: Endpoint = Endpoint(),
        pagingInfo: PagingMeta? = nil,
        delayMillis: Int = 10
    ) -> NetCallReducer.State {
        return NetCallReducer.State(
            session: URLSession(configuration: .default),
            baseUrl: URLComponents(string: "https://example.com/api/v1/")!,
            endpoint: endpoint,
            pagingInfo: pagingInfo,
            firingFunc: NetCallReducer.mockFire(with: data, error: error, delayMillis: delayMillis)
        )
    }

    // MARK: - 1. testRefreshFiresModelsCallRefresh

    func testRefreshFiresModelsCallRefresh() async throws {
        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [],
            modelsCallState: makeCallState(data: "[]".data(using: .utf8)),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.refresh)
        await store.receive(.modelsCall(.refresh))

        await store.finish()
    }

    // MARK: - 2. testNextPageFiresModelsCallNextPage

    func testNextPageFiresModelsCallNextPage() async throws {
        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [],
            modelsCallState: makeCallState(data: "[]".data(using: .utf8)),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.nextPage)
        await store.receive(.modelsCall(.nextPage))

        await store.finish()
    }

    // MARK: - 3. testResponseDataWithUnwrapEmitsDidUpdateModels

    func testResponseDataWithUnwrapEmitsDidUpdateModels() async throws {
        let id = UUID()
        let json = """
        {"wordbooks": [{"id": "\(id.uuidString)", "name": "Test", "key": "k1"}]}
        """
        let data = json.data(using: .utf8)!

        let initialState = NetModelsReducer<Worterbuch, WorterbuchsWrapper>.State(
            models: [],
            modelsCallState: makeCallState(data: data),
            unwrap: { $0.wordbooks }
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Worterbuch, WorterbuchsWrapper>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.refresh)

        let expected = Worterbuch(id: id, name: "Test", key: "k1")
        await store.receive(.delegate(.didUpdateModels([expected])))

        await store.finish()
    }

    // MARK: - 4. testResponseDataWithoutUnwrapDecodesArray

    func testResponseDataWithoutUnwrapDecodesArray() async throws {
        // Phrase encodes id (String), translation (String), createdAt (Date).
        // The shared decoder uses .convertFromSnakeCase, so JSON "created_at"
        // maps to Swift "createdAt". Date is decoded by JSONDecoder's default
        // strategy (`.deferredToDate`), which is reference-time-interval seconds.
        let createdAtRefDate = Date(timeIntervalSinceReferenceDate: 1000)
        let phrase = Phrase(id: "hund", translation: "dog", createdAt: createdAtRefDate)

        let json = """
        [{"id":"hund","translation":"dog","created_at":1000}]
        """
        let data = json.data(using: .utf8)!

        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [],
            modelsCallState: makeCallState(data: data),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.refresh)

        // Phrase.== compares only `id`, so this also documents that
        // translation/createdAt aren't part of equality.
        await store.receive(.delegate(.didUpdateModels([phrase])))

        await store.finish()
    }

    // MARK: - 5. testPagedResponseAppendsToModels

    func testPagedResponseAppendsToModels() async throws {
        // Pre-existing model in state (page 1 already loaded).
        let existing = Phrase(id: "alpha", translation: "first", createdAt: Date(timeIntervalSinceReferenceDate: 0))
        let incoming = Phrase(id: "beta", translation: "second", createdAt: Date(timeIntervalSinceReferenceDate: 1))

        // Endpoint with `page=2` query param so `isNotFirstPage` returns true.
        var endpoint = Endpoint()
        endpoint.getParams = [URLQueryItem(name: "page", value: "2")]

        let json = """
        [{"id":"beta","translation":"second","created_at":1}]
        """
        let data = json.data(using: .utf8)!

        let pagingInfo = PagingMeta()  // defaults: pageKey "page", firstPage 1

        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [existing],
            modelsCallState: makeCallState(data: data, endpoint: endpoint, pagingInfo: pagingInfo),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Use `.nextPage` so we don't reset pagination — `.refresh` resets the
        // page param back to firstPage when pagingInfo is set.
        await store.send(.nextPage)

        // After incrementPageParams, page becomes 3 (was 2). Either way,
        // isNotFirstPage stays true, so the previous models are preserved.
        await store.receive(.delegate(.didUpdateModels([existing, incoming])))

        await store.finish()
    }

    // MARK: - 6. testErrorPopulatesAlert

    func testErrorPopulatesAlert() async throws {
        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [],
            modelsCallState: makeCallState(error: NSError(domain: "Server", code: 401)),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.refresh)
        await store.skipReceivedActions()

        // 401 is mapped to "Unauthorized" by `urlResponseErrorMessages`.
        XCTAssertNotNil(store.state.alert)

        await store.finish()
    }

    // MARK: - 7. testUnknownErrorCodeDoesNotSetAlert

    func testUnknownErrorCodeDoesNotSetAlert() async throws {
        let initialState = NetModelsReducer<Phrase, [Phrase]>.State(
            models: [],
            modelsCallState: makeCallState(error: NSError(domain: "Server", code: -99999)),
            unwrap: nil
        )
        let store = TestStore(initialState: initialState) {
            NetModelsReducer<Phrase, [Phrase]>()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.refresh)
        await store.skipReceivedActions()

        // -99999 is in neither `urlLoadingErrorCodesDict` nor
        // `urlResponseErrorMessages`, so no alert is presented.
        XCTAssertNil(store.state.alert)

        await store.finish()
    }
}
