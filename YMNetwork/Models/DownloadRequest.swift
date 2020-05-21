//
//  DownloadRequest.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 22.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public struct DownloadStruct {

    public var isDownloading: Bool = false
    public var progress: Float = 0.0
    public var resumeData: Data? = nil
    public var downloadTask: URLSessionDownloadTask? = nil
    public var delegate: YMNetworkManagerDownloadDelegate? = nil

    public init() {}
}

public protocol YMDownloadRequest: YMRequest {

    var path: String { get }
    var download: DownloadStruct? { get set }
}

public extension YMDownloadRequest {

    var isDownloading: Bool {
        get { return download?.isDownloading ?? false }
        set { download?.isDownloading = newValue }
    }
    var progress: Float {
        get { return download?.progress ?? 0.0 }
        set { download?.progress = newValue  }
    }
    var resumeData: Data? {
        get { return download?.resumeData }
        set { download?.resumeData = newValue }
    }
    var downloadTask: URLSessionDownloadTask? {
        get { return download?.downloadTask }
        set { download?.downloadTask = newValue }
    }
    var delegate: YMNetworkManagerDownloadDelegate? {
        get { return download?.delegate }
        set { download?.delegate = newValue }
    }

    var task: HTTPTaskType {
        return .download
    }
}
