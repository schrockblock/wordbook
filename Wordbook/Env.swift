//
//  Env.swift
//  Template
//
//  Created by Elliot Schrock on 3/5/24.
//

import Foundation
import FunNetTCA
import FunNetCore
import ComposableArchitecture

public func apiEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}

public func apiDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}

public struct Env {
    @Dependency(\.uuid) var uuid
    
    public var session: URLSession
    public var baseUrl: URLComponents
    public var apiJsonEncoder: JSONEncoder
    public var apiJsonDecoder: JSONDecoder
    
    public init(session: URLSession = URLSession(configuration: .default), baseUrl: URLComponents = URLComponents(string: "https://template.heroku.com/api/v1/")!, apiJsonEncoder: JSONEncoder = JSONEncoder(), apiJsonDecoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.baseUrl = baseUrl
        self.apiJsonEncoder = apiJsonEncoder
        self.apiJsonDecoder = apiJsonDecoder
    }
    
    func netState(from endpoint: Endpoint, pagingInfo: PagingMeta? = nil, reset: ((inout Endpoint) -> Void)? = nil) -> NetCallReducer.State {
        return NetCallReducer.State(session: session, baseUrl: baseUrl, endpoint: endpoint, pagingInfo: pagingInfo, reset: reset)
    }
    
    func mockNetState(from endpoint: Endpoint, with data: Data, delay: Int = 100) -> NetCallReducer.State {
        return NetCallReducer.State(session: session, baseUrl: baseUrl, endpoint: endpoint, firingFunc: NetCallReducer.mockFire(with: data, delayMillis: delay))
    }
}

var Current = Env(apiJsonEncoder: apiEncoder(), apiJsonDecoder: apiDecoder())
