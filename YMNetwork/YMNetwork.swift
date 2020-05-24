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
    _ result: YMResult<T>,
    _ error: Error?
    ) -> ()

// MARK: - YMNetworkCommunication

public protocol YMNetworkCommunication: class {

    func request<T: YMResponse>(
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
}

// MARK: - YMNetworkManager

public class YMNetworkManager: NSObject, YMNetworkCommunication {

    // MARK: - Data
    private var dataTask: URLSessionTask?

    // MARK: - Download
    lazy var downloadsSession: URLSession = {

        let configuration = URLSessionConfiguration.default

        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    private var downloadTask: URLSessionDownloadTask?

    // MARK: - Upload
    lazy var uploadsSession: URLSession = {
        let conf = URLSessionConfiguration.default
        return URLSession(
            configuration: conf,
            delegate: self,
            delegateQueue: nil
        )
    }()
    private var uploadTask: URLSessionUploadTask?

    // MARK: - Properties

    private var configuration: YMNetworkConfiguration
    public weak var delegate: YMNetworkManagerDownloadDelegate?

    // MARK: - Lifecycle

    public init(configuration: YMNetworkConfiguration) {

        self.configuration = configuration
    }


    /// General request method. It's gateway of all request types conforms to `YMRequest`. Request
    /// task types are `data`, `download` and `upload`.
    /// - Parameters:
    ///   - request: YMRequest
    ///   - completion: `YMNetworkCompletion<response: HTTPURLResponse?, _ result: YMResult<T>, error: Error?>`
    public func request<T: YMResponse>(
        _ request: YMRequest,
        completion: @escaping YMNetworkCompletion<T>
    ) {

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
                        let result: YMResult<T> = self?.handleNetworkResponse(
                            Response(response: urlResponse, data: data)
                            ) ?? .failure(.failed)
                        completion(urlResponse, result, error)
                    }
                )
                dataTask?.resume()
            case .upload:
                guard let uploadRequest = request as? YMUploadRequest,
                    let fileURL = uploadRequest.fileURL else { return }
                uploadTask = uploadsSession.uploadTask(
                    with: urlRequest,
                    fromFile: fileURL,
                    completionHandler: { [weak self] (data, response, error) in

                        defer {
                            self?.uploadTask = nil
                        }

                        guard let urlResponse = response as? HTTPURLResponse else { return }
                        let result: YMResult<T> = self?.handleNetworkResponse(
                            Response(response: urlResponse, data: data)
                            ) ?? .failure(.failed)
                        completion(urlResponse, result, error)
                })
                uploadTask?.resume()
            default:
                break
            }
        } catch {
            completion(nil, .failure(.failed), error)
        }
    }


    /// Cancels current data task.
    public func cancelDataTask() {

        dataTask?.cancel()
    }

    /// Handles network response regarding it's status code.
    /// - Parameter response: YMResponse
    /// - Returns: YMResult
    fileprivate func handleNetworkResponse<T: YMResponse>(_ response: Response) -> YMResult<T> {

        guard let statusCode = response.response?.statusCode else {
            return .failure(.unknown)
        }
        switch statusCode {
        case 200...299:
            do {
                guard let data = response.data else { return .failure(.noData) }
                let apiResponse = try JSONDecoder().decode(T.self, from: data)
                return YMResult.success(apiResponse)
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


    /// Build urlrequest for any type of YMRequest.
    /// - Parameter request: YMRequest
    /// - Returns: URLRequest
    fileprivate func buildRequest(from request: YMRequest) throws -> URLRequest? {

        guard let baseURL = URL(string: configuration.baseURL) else { return nil }
        var urlRequest = URLRequest(
            url: baseURL.appendingPathComponent(request.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: configuration.timeoutInterval
        )

        urlRequest.httpMethod = request.method.rawValue
        addAdditionalHeaders(configuration.headers, request: &urlRequest)

        do {
            switch request.task {
            case .data:
                try configureParameters(
                    bodyParameters: request.bodyParameters,
                    urlParameters: request.urlParameters,
                    request: &urlRequest
                )
            case .upload:
                // TODO: Add upload with data support
                break
            default:
                break
            }
            return urlRequest
        } catch {
            throw error
        }
    }


    /// Encode body and url parameters.
    /// - Parameters:
    ///   - bodyParameters: Body parameters.
    ///   - urlParameters: URL parameters.
    ///   - request: `URLRequest`.
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


    /// Adds additional headers to default http headers for given request.
    /// - Parameters:
    ///   - additionalHeaders: HTTPHeaders
    ///   - request: URLReques
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

    /// Start to download file for given request.
    /// - Parameter request: YMDownloadRequest
    func download(with request: inout YMDownloadRequest?) throws {

        guard let ymRequest = request,
            let urlRequest = try? buildRequest(from: ymRequest),
            let url = urlRequest.url else { return }

        if let activeDownload = YMDownloadManager.shared.activeDownloads[url],
            !activeDownload.isDownloading {
            resumeDownloadTask(of: activeDownload)
        } else {
            downloadTask = downloadsSession.downloadTask(with: urlRequest)
            downloadTask?.resume()
            request?.isDownloading = true
            request?.downloadTask = downloadTask
            delegate = request?.delegate
            YMDownloadManager.shared.activeDownloads[url] = request
        }
    }

    /// Pause current download request if it is downloading.
    /// - Parameter request: YMDownloadRequest
    func pauseDownloadTask(of request: YMDownloadRequest) {

        do {
            guard let url = try buildRequest(from: request)?.url,
                let req = YMDownloadManager.shared.activeDownloads[url],
                req.isDownloading else { return }

            req.downloadTask?.cancel(byProducingResumeData: { (data) in
                req.isDownloading = false
                req.resumeData = data
                YMDownloadManager.shared.activeDownloads[url] = req
            })
        } catch(let error) {
            print(error.localizedDescription)
        }
    }

    /// Cancels current download request.
    /// - Parameter request: YMDownloadRequest
    func cancelDownloadTask(of request: YMDownloadRequest) {

        do {
            guard let url = try buildRequest(from: request)?.url,
                let req = YMDownloadManager.shared.activeDownloads[url] else { return }
            req.downloadTask?.cancel()
            req.isDownloading = false
            req.resumeData = nil
            req.progress = .zero
            YMDownloadManager.shared.activeDownloads[url] = req
        } catch(let error) {
            print(error.localizedDescription)
        }
    }

    /// Resume to download task if it's not already downloading and has resume data.
    /// - Parameters:
    ///   - request: `YMDownloadRequest`
    ///   - completion: `(_ status: Bool, _ error: String?)`
    func resumeDownloadTask(
        of request: YMDownloadRequest?,
        completion: ((_ status: Bool, _ error: String?) -> ())? = nil
    ) {

        do {
            guard let request = request,
                let url = try buildRequest(from: request)?.url,
                let req = YMDownloadManager.shared.activeDownloads[url],
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
            YMDownloadManager.shared.activeDownloads[url] = req
            req.downloadTask?.resume()
            completion?(true, nil)
        } catch(let error) {
            completion?(false, error.localizedDescription)
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
        let downloadRequest = YMDownloadManager.shared.activeDownloads[url]
        downloadRequest?.isDownloading = false
        downloadRequest?.progress = 1.0
        downloadRequest?.resumeData = nil
        YMDownloadManager.shared.activeDownloads[url] = downloadRequest

        delegate?.ymNetworkManager(
            self,
            request: downloadRequest,
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
        let downloadRequest = YMDownloadManager.shared.activeDownloads[url]
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        downloadRequest?.progress = progress
        YMDownloadManager.shared.activeDownloads[url] = downloadRequest

        delegate?.ymNetworkManager(
            self,
            request: downloadRequest,
            downloadTask: downloadTask
        )
    }
}
