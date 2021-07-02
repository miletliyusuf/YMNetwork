//
//  Response.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 15.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

// MARK: - YMResponse

public protocol YMResponse: Codable {}

public extension YMResponse {

    func encode(to encoder: Encoder) throws {}
}

// MARK: - YMModel

public protocol YMModel : Decodable, Encodable {}

// MARK: - YMNetworkError

public enum YMNetworkError {

    case success
    case authenticationError
    case badRequest
    case outdated
    case failed
    case noData
    case unableToDecode
    case unknown
    case timedOut
    case decodingFailed(reason: String)

    public var humanReadable: String {
        switch self {
        case .success: return "Success!"
        case .authenticationError: return "You need to be authenticated first."
        case .badRequest: return "Bad Request"
        case .outdated: return "The url you requested is outdated."
        case .failed: return "Network requst failed."
        case .noData: return "Response returned with no data to decode."
        case .unableToDecode: return "We could not decode the response."
        case .unknown: return "Unknown status code."
        case .timedOut: return "Request timed out."
        case .decodingFailed(let error): return "Failed to decode data. Error:" + error
        }
    }
}

// MARK: - YMResult

public enum YMResult<Value> {

    case success(Value)
    case failure(YMNetworkError)
}

// MARK: - Response

public struct Response {

    public var response: HTTPURLResponse?
    public var data: Data?

    public init(
        response: HTTPURLResponse?,
        data: Data?
    ) {

        self.response = response
        self.data = data
    }
}
