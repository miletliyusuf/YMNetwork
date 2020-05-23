//
//  UploadRequest.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 5.05.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

// MARK: - YMUploadRequest

public protocol YMUploadRequest: YMRequest {

    var fileURL: URL? { get set }
}

public extension YMUploadRequest {

    var task: HTTPTaskType { return .upload }
    var method: HTTPMethod { return .post }
}
