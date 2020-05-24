# YMNetwork

HTTP Networking library written in Swift. 

![YMNetwork](https://i.ibb.co/SxRgtw5/ymnetwork-Logo.png)

[![Swift Version][swift-image]][swift-url]
[![Build Status][travis-image]][travis-url]
[![License][license-image]][license-url]
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/EZSwiftExtensions.svg)](https://img.shields.io/cocoapods/v/LFAlertController.svg)  
[![Platform](https://img.shields.io/cocoapods/p/LFAlertController.svg?style=flat)](http://cocoapods.org/pods/LFAlertController)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

## Requirements

- iOS 8.0+
- Xcode 11+
- Swift 5.0+

## Usage

YMNetwork has been designed to create HTTP requests very easily.

**IMPORTANT NOTE:** If you're implementing via **Cocoapods** you need to import framework as `import YMNetwork_Swift` and for **Carthage** `import YMNetwork` is enough. Please see [Installation](#installation) for detail informations.

## Features

- [Object Mapping](#mapping)
- [Easy Download Management](#download-management)
- [Basic HTTP Requests (GET, POST, PUT, DELETE)](#http-requests)
- [File Upload](#file-upload)

### Mapping

Mapping is super easy in YMNetwork. You just need to conform your response struct to `YMResponse` and model to `YMModel`.

```swift
struct MovieResponse: YMResponse {

    private enum CodingKeys: String, CodingKey {

        case page
        case numberOfResults = "total_results"
        case numberOfPages = "total_pages"
        case movies = "results"
    }

    let page: Int
    let numberOfResults: Int
    let numberOfPages: Int
    let movies: [Movie]
}

// MARK: - Movie

struct Movie: YMModel {

    let id: Int
    let posterPath: String
    let backdrop: String
    let title: String
    let releaseDate: String
    let rating: Double
    let overview: String

    enum CodingKeys: String, CodingKey {
        case id
        case posterPath = "poster_path"
        case backdrop = "backdrop_path"
        case title
        case releaseDate = "release_date"
        case rating = "vote_average"
        case overview
    }
}
```

### Download Management

Create your download requests using `YMDownloadRequest`. If you conform `YMNetworkManagerDownloadDelegate` in your class you will be able to manage and see progress all your downloads on 

```swift
func ymNetworkManager(_ manager: YMNetworkManager, request: YMDownloadRequest?, downloadTask: URLSessionDownloadTask)
```

You can also `pause`, `resume` or `cancel` your download tasks.

```swift
private let manager = YMNetworkManager(
        configuration: YMNetworkConfiguartion(
            baseURL: environment.baseURL,
            headers: [:]
        )
    )

// Start Download
try? manager.shared.download(with: &request)

// Pause Download
manager.pauseDownloadTask(of: request)

// Resume Download
manager.resumeDownloadTask(of: request) { (status, error) in
            completion(status, error)
        }

// Cancel Download
manager.cancelDownloadTask(of: request)

```

### HTTP Requests

You can manage your request requirements on your request class by conforming it to `YMRequest`. 

All possible values are:
```swift
var path: String { get }
var method: HTTPMethod { get }
var headers: HTTPHeaders? { get }
var bodyParameters: Parameters? { get }
var urlParameters: Parameters? { get }
var task: HTTPTaskType { get }
```

Simple usage:
```swift
struct MovieRequest: BaseRequest {

    var path: String = "now_playing"
    var urlParameters: Parameters?

    init(page: Int) {

        urlParameters?["page"] = page
    }
}

// Send request

private let manager = YMNetworkManager(
        configuration: YMNetworkConfiguartion(
            baseURL: environment.baseURL,
            headers: [:]
        )
    )
    
let request = MovieRequest(page: 1)

manager.request(request) { (response, result: YMResult<T>, error) in

    if error != nil {
	completion(nil, "Please check your network connection")
    }

    switch result {
    case .success(let data):
	completion(data, nil)
    case .failure(let error):
	completion(nil, error.rawValue)
    }
}

```

### File Upload

You can upload your files by passing it's file url into `YMUploadRequest`.

```swift
struct UploadRequest: YMUploadRequest {

    var fileURL: URL?
    var path: String = "post"
    
    init(fileURL: URL?) {
    	
	self.fileURL = fileURL
    }
}

let request = UploadRequest(fileURL: Bundle.main.url(forResource: "cat", withExtension: "jpg"))

private let manager = YMNetworkManager(
        configuration: YMNetworkConfiguartion(
            baseURL: environment.baseURL,
            headers: [:]
        )
    )
    
manager.request(request) { (response, result: YMResult<T>, error) in

    if error != nil {
	completion(nil, "Please check your network connection")
    }

    switch result {
    case .success(let data):
	completion(data, nil)
    case .failure(let error):
	completion(nil, error.rawValue)
    }
}
```

## Installation

### CocoaPods

Well.. `YMNetwork` is already taken for cocoapods. You should be installing pod as `pod 'YMNetwork-Swift'` but when you import framework in your code please just use `import YMNetwork_Swift`

Check out [Get Started](http://cocoapods.org/) tab on [cocoapods.org](http://cocoapods.org/).

To use YMNetwork in your project add the following 'Podfile' to your project

	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, '8.0'
	use_frameworks!

	pod 'YMNetwork-Swift'

Then run:

    pod install

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `YMNetwork` framework is already setup with shared schemes.

[Carthage Install](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate YMNetwork into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "miletliyusuf/YMNetwork" >= 1.0.0
```

## TODO

- [ ] Better Upload Management
- [ ] Image caching
- [ ] Better support for URLSession configurations
- [ ] Upload with Data
- [ ] Better Documentation

## Meta

Yusuf Miletli – [Linkedin](https://www.linkedin.com/in/miletliyusuf/), miletliyusuf@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/miletliyusuf/YMNetwork](https://github.com/miletliyusuf/YMNetwork)

[swift-image]:https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
