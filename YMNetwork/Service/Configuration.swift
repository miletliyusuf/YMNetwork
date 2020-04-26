//
//  Configuration.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 18.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

// MARK: - YMNetworkConfiguartion

public struct YMNetworkConfiguartion {

    // TODO: - Add all possible configurations

    var baseURL: String
    var headers: HTTPHeaders
    var timeoutInterval: TimeInterval

    public init(
        baseURL: String,
        headers: HTTPHeaders,
        timeoutInterval: TimeInterval = 10.0
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.timeoutInterval = timeoutInterval
    }
}
