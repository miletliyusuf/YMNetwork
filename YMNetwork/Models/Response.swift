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

// MARK: - YMNetworkResponse

public enum YMNetworkResponse: String {

    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad Request"
    case outdated = "The url you requested is outdated."
    case failed = "Network requst failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
    case unknown = "Unknown status code."
    case decodingFailed = "Failed to decode data."
}

// MARK: - YMResult

public enum YMResult<Value> {

    case success(Value)
    case failure(YMNetworkResponse)
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
