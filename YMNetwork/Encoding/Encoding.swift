//
//  ParameterEncoding.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 12.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]

// MARK: - Constants

fileprivate enum Constants {

    static let appropriateHeaderField = "Content-Type"
    static let appropriateURLEncodedHeader = "application/x-www-form-urlencoded; charset=utf-8"
    static let appropriateJSONEncodedHeader = "application/x-www-form-urlencoded; charset=utf-8"
}

// MARK: - ParameterEncooder

public protocol ParameterEncoder {

    static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

// MARK: - URLParameterEncoder

public struct URLParameterEncoder: ParameterEncoder {

    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {

        guard let url = urlRequest.url else {
            throw NetworkError.missingURL
        }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            !parameters.isEmpty {

            urlComponents.queryItems = [URLQueryItem]()

            for (key, value) in parameters {

                let item = URLQueryItem(
                    name: key,
                    value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                )
                urlComponents.queryItems?.append(item)
            }

            urlRequest.url = urlComponents.url
        }

        if urlRequest.value(forHTTPHeaderField: Constants.appropriateHeaderField) == nil {
            urlRequest.setValue(
                Constants.appropriateURLEncodedHeader,
                forHTTPHeaderField: Constants.appropriateHeaderField
            )
        }
    }
}

// MARK: - JSONParameterEncoder

public struct JSONParameterEncoder: ParameterEncoder {

    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {

        do {
            let jsonAsData = try JSONSerialization.data(
                withJSONObject: parameters,
                options: .prettyPrinted
            )
            urlRequest.httpBody = jsonAsData
            if urlRequest.value(forHTTPHeaderField: Constants.appropriateHeaderField) == nil {
                urlRequest.setValue(
                    Constants.appropriateJSONEncodedHeader,
                    forHTTPHeaderField: Constants.appropriateHeaderField
                )
            }
        } catch {
            throw NetworkError.encodingFailed
        }
    }
}
