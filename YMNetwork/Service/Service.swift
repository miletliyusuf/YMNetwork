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

// MARK: - HTTPTask

public enum HTTPTaskType {

    case data
    case download
    case upload
}

// MARK: - NetworkError

public enum NetworkError: String, Error {

    case parametersNil = "Paramters were nil."
    case encodingFailed = "Paramter encoding failed."
    case missingURL = "URL is nil."
}
