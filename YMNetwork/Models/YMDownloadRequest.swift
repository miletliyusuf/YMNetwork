//
//  DownloadRequest.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 22.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

// MARK - YMDownloadRequest

open class YMDownloadRequest: YMRequest {

    public var path: String = ""
    public var isDownloading: Bool = false
    public var progress: Float = 0.0
    public var resumeData: Data? = nil
    public var downloadTask: URLSessionDownloadTask? = nil
    public weak var delegate: YMNetworkManagerDownloadDelegate? = nil

    /// Public initializer of YMDownloadRequest.
    /// - Parameters:
    ///   - path: Download path in `String`
    ///   - delegate: YMNetworkManagerDelegate. Default is `nil`.
    public init(path: String, delegate: YMNetworkManagerDownloadDelegate? = nil) {

        self.path = path
        self.delegate = delegate
    }
}

public extension YMDownloadRequest {

    var task: HTTPTaskType {
        return .download
    }
}

public extension YMDownloadRequest {

    /// Checks if given request parameter is equal.
    /// - Parameter request: YMDownloadRequest
    /// - Returns: Equality result in `Bool`
    func isEqual(to request: YMDownloadRequest?) -> Bool {

        guard let request = request else { return false }
        return self.path == request.path
    }
}
