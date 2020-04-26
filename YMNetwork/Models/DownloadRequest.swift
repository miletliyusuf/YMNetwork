//
//  DownloadRequest.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 22.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public protocol YMDownloadRequest: YMRequest {

    var path: String { get }
    var isDownloading: Bool { get set }
    var progress: Float { get set }
    var resumeData: Data? { get set }
    var downloadTask: URLSessionDownloadTask? { get set }
    var delegate: YMNetworkManagerDownloadDelegate? { get }
}

//public extension YMDownloadRequest {
//
//    var isDownloading: Bool {
//        get {
//            return false
//        }
//    }
//    var progress: Float {
//        get {
//            return 0.0
//        } set {
//            progress = newValue
//        }
//    }
//    var resumeData: Data? {
//        get {
//            return nil
//        } set {
//            resumeData = newValue
//        }
//    }
//    var downloadTask: URLSessionDownloadTask? {
//        get {
//            return nil
//        } set {
//            downloadTask = newValue
//        }
//    }
//    var delegate: YMNetworkManagerDownloadDelegate? {
//        get {
//            return nil
//        }
//    }
//}
