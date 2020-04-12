//
//  Service.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 12.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [String: String]

// MARK: - HTTPMethod

public enum HTTPMethod: String {

    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - EndPointType

public protocol EndPointType {

    var baserURL: URL { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: HTTPHeaders? { get }
}

// MARK: - HTTPTask

public enum HTTPTask {

    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)
    case requestParametersAndHeaders(
        bodyParameters: Parameters?,
        urlParameters: Parameters?,
        additionHeaders: HTTPHeaders?
    )

    // TODO:
    // case download
    // case upload
}

// MARK: - NetworkError

public enum NetworkError: String, Error {

    case parametersNil = "Paramters were nil."
    case encodingFailed = "Paramter encoding failed."
    case missingURL = "URL is nil."
}
