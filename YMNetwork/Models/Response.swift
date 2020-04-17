//
//  Response.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 15.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public enum NetworkResponse: String {

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

public enum Result<Value> {

    case success(Value)
    case failure(NetworkResponse)
}

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

// Codable response protocol that conforms to Codable
public protocol CodableResponse: Codable {}

public extension CodableResponse {

    func encode(to encoder: Encoder) throws {}
}
