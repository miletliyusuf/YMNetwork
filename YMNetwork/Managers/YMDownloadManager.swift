//
//  YMDownloadManager.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 23.05.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public class YMDownloadManager {

    static let shared = YMDownloadManager()

    var activeDownloads: [URL?: YMDownloadRequest] = [:]
}
