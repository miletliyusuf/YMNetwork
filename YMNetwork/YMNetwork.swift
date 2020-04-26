//
//  YMNetwork.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 12.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public typealias YMNetworkCompletion<T> = (
    _ response: HTTPURLResponse?,
    _ result: Result<T>,
    _ error: Error?
    ) -> ()

// MARK: - NetworkCommunication

public protocol NetworkCommunication: class {

    func request<T: CodableResponse>(
        _ request: YMRequest,
        completion: @escaping YMNetworkCompletion<T>
    )
    func cancelDataTask()
}

// MARK: - YMNetworkManagerDownloadDelegate

public protocol YMNetworkManagerDownloadDelegate: AnyObject {

    func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    )

    func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        downloadTask: URLSessionDownloadTask
    )

    func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        didDownloadBecomeInvalidWithError error: Error?
    )
}

extension YMNetworkManagerDownloadDelegate {

    public func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {}

    public func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        downloadTask: URLSessionDownloadTask
    ) {}

    public func ymNetworkManager(
        _ manager: YMNetworkManager,
        request: YMDownloadRequest?,
        didDownloadBecomeInvalidWithError error: Error?
    ) {}
}

// MARK: - YMNetworkManager

public class YMNetworkManager: NSObject, NetworkCommunication {

    private var dataTask: URLSessionTask?
    lazy var downloadsSession: URLSession = {

        let configuration = URLSessionConfiguration.default

        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    private var downloadTask: URLSessionDownloadTask?
    private var uploadTask: URLSessionUploadTask?
    private var configuration: YMNetworkConfiguartion
    public weak var delegate: YMNetworkManagerDownloadDelegate?

    public var activeDownloads: [URL?: YMDownloadRequest] = [:]

    public init(configuration: YMNetworkConfiguartion) {

        self.configuration = configuration
    }


    /// <#Description#>
    /// - Parameters:
    ///   - request: <#request description#>
    ///   - completion: <#completion description#>
    public func request<T: CodableResponse>(
        _ request: YMRequest,
        completion: @escaping YMNetworkCompletion<T>
    ) {

        // TODO: Improve
        do {
            guard let urlRequest = try buildRequest(from: request) else { return }

            switch request.task {
            case .data:
                let session = URLSession(configuration: .default)
                dataTask = session.dataTask(
                    with: urlRequest,
                    completionHandler: { [weak self] (data, response, error) in

                        defer {
                            self?.dataTask = nil
                        }

                        guard let urlResponse = response as? HTTPURLResponse else { return }
                        let result: Result<T> = self?.handleNetworkResponse(
                            Response(response: urlResponse, data: data)
                            ) ?? .failure(.failed)
                        completion(urlResponse, result, error)
                    }
                )
                dataTask?.resume()
            case .download:

                guard let url = urlRequest.url,
                    var downloadRequest = request as? YMDownloadRequest else { return }
                if let activeDownload = activeDownloads[url] {
                    if !activeDownload.isDownloading {
                        resumeDownloadTask(of: downloadRequest)
                    }
                } else {
                    downloadTask = downloadsSession.downloadTask(with: urlRequest)
                    downloadTask?.resume()
                    downloadRequest.isDownloading = true
                    downloadRequest.downloadTask = downloadTask
                    delegate = downloadRequest.delegate
                    activeDownloads[url] = downloadRequest
                }
            case .upload:
                break
            }
        } catch {
            completion(nil, .failure(.failed), error)
        }
    }


    /// <#Description#>
    public func cancelDataTask() {

        dataTask?.cancel()
    }

    /// <#Description#>
    /// - Parameter response: <#response description#>
    fileprivate func handleNetworkResponse<T: CodableResponse>(_ response: Response) -> Result<T> {

        guard let statusCode = response.response?.statusCode else {
            return .failure(.unknown)
        }
        switch statusCode {
        case 200...299:
            do {
                guard let data = response.data else { return .failure(.noData) }
                let apiResponse = try JSONDecoder().decode(T.self, from: data)
                return Result.success(apiResponse)
            } catch {
                return .failure(.decodingFailed)
            }

        case 401...500:
            return .failure(.authenticationError)
        case 501...599:
            return .failure(.badRequest)
        case 600:
            return .failure(.outdated)
        default:
            return .failure(.failed)
        }
    }


    /// <#Description#>
    /// - Parameter request: <#request description#>
    fileprivate func buildRequest(from request: YMRequest) throws -> URLRequest? {

        guard let baseURL = URL(string: configuration.baseURL) else { return nil }
        var urlRequest = URLRequest(
            url: baseURL.appendingPathComponent(request.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: configuration.timeoutInterval
        )

        urlRequest.httpMethod = request.method.rawValue

        do {
            addAdditionalHeaders(configuration.headers, request: &urlRequest)

            try configureParameters(
                bodyParameters: request.bodyParameters,
                urlParameters: request.urlParameters,
                request: &urlRequest
            )
            return urlRequest
        } catch {
            throw error
        }
    }


    /// <#Description#>
    /// - Parameters:
    ///   - bodyParameters: <#bodyParameters description#>
    ///   - urlParameters: <#urlParameters description#>
    ///   - request: <#request description#>
    fileprivate func configureParameters(
        bodyParameters: Parameters?,
        urlParameters: Parameters?,
        request: inout URLRequest
    ) throws {

        do {
            if let bodyParameters = bodyParameters {
                try? JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }

            if let urlParameters = urlParameters {
                try? URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        }
    }


    /// <#Description#>
    /// - Parameters:
    ///   - additionalHeaders: <#additionalHeaders description#>
    ///   - request: <#request description#>
    fileprivate func addAdditionalHeaders(
        _ additionalHeaders: HTTPHeaders?,
        request: inout URLRequest
    ) {

        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}

// MARK: - Download Helpers

public extension YMNetworkManager {

    func pauseDownloadTask(of request: YMDownloadRequest) {

        do {
            guard let url = try buildRequest(from: request)?.url,
                var req = activeDownloads[url],
                req.isDownloading else { return }

            req.downloadTask?.cancel(byProducingResumeData: { [weak self] (data) in
                req.isDownloading = false
                req.resumeData = data
                self?.activeDownloads[url] = req
            })
        } catch {
            // TODO
        }
    }

    func cancelDownloadTask(of request: YMDownloadRequest) {

        do {
            guard let url = try buildRequest(from: request)?.url,
                var req = activeDownloads[url] else { return }
            req.downloadTask?.cancel()
            req.isDownloading = false
            req.resumeData = nil
            req.progress = .zero
            activeDownloads[url] = req
        } catch {
            // TODO
        }
    }

    func resumeDownloadTask(
        of request: YMDownloadRequest,
        completion: ((_ status: Bool, _ error: String?) -> ())? = nil
    ) {

        do {
            guard let url = try buildRequest(from: request)?.url,
                var req = activeDownloads[url],
            !req.isDownloading else { return }

            if let resumeData = req.resumeData {
                req.downloadTask = downloadsSession.downloadTask(withResumeData: resumeData)
            } else {
                do {
                    guard let urlRequest = try buildRequest(from: req) else { return }
                    req.downloadTask = downloadsSession.downloadTask(with: urlRequest)
                } catch (let error) {
                    completion?(false, error.localizedDescription)
                }
            }
            req.isDownloading = true
            activeDownloads[url] = req
            req.downloadTask?.resume()
            completion?(true, nil)
        } catch {
            // TODO
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension YMNetworkManager: URLSessionDownloadDelegate {

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {

        guard let url = downloadTask.currentRequest?.url else { return }
        var download = activeDownloads[url]
        download?.isDownloading = false
        download?.progress = 1.0
        download?.resumeData = nil
        activeDownloads[url] = download

        delegate?.ymNetworkManager(
            self,
            request: download,
            downloadTask: downloadTask,
            didFinishDownloadingTo: location
        )
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {

        guard let url = downloadTask.currentRequest?.url else { return }
        var download = activeDownloads[url]
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        download?.progress = progress
        activeDownloads[url] = download

        delegate?.ymNetworkManager(
            self,
            request: download,
            downloadTask: downloadTask
        )
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

//        var download = activeDownloads[downloadTask]
//
//        download?.isDownloading = false
//        download?.progress = .zero
//        download?.resumeData = nil
//        activeDownloads[downloadTask] = download
//
//        delegate?.ymNetworkManager(
//            self,
//            request: download,
//            didDownloadBecomeInvalidWithError: error
//        )
    }
}
