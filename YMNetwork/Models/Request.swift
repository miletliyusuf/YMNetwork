//
//  Request.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 17.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

// MARK: - YMRequest

public protocol YMRequest {

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var bodyParameters: Parameters? { get }
    var urlParameters: Parameters? { get }
    var task: HTTPTaskType { get }
}

public extension YMRequest {

    var method: HTTPMethod { return .get }
    var headers: HTTPHeaders? { return nil }
    var bodyParameters: Parameters? { return nil }
    var urlParameters: Parameters? { return nil }
    var task: HTTPTaskType { return .data }
}
