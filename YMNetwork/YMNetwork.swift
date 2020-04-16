//
//  YMNetwork.swift
//  YMNetwork
//
//  Created by Yusuf Miletli on 12.04.2020.
//  Copyright © 2020 Miletli. All rights reserved.
//

import Foundation

public typealias YMNetworkCompletion = (
    _ data: Data?,
    _ response: URLResponse?,
    _ error: Error?
    ) -> ()

// MARK: - NetworkCommunication

public protocol NetworkCommunication: class {

    func request(_ request: YMRequest, completion: @escaping YMNetworkCompletion)
    func cancel()
}

// MARK: - YMNetworkConfiguartion

public struct YMNetworkConfiguartion {

    // TODO: - Add all possible configurations

    var baseURL: String
    var headers: HTTPHeaders

    public init(
        baseURL: String,
        headers: HTTPHeaders
    ) {
        self.baseURL = baseURL
        self.headers = headers
    }
}

// MARK: - YMNetworkManager

public class YMNetworkManager: NetworkCommunication {

    private var task: URLSessionTask?
    private var configuration: YMNetworkConfiguartion

    public init(configuration: YMNetworkConfiguartion) {

        self.configuration = configuration
    }

    public func request(_ request: YMRequest, completion: @escaping YMNetworkCompletion) {

        let session = URLSession.shared

        // TODO: Improve
        do {
            guard let request = try self.buildRequest(from: request) else { return }
            task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                completion(data, response, error)
            })
        } catch {
            completion(nil, nil, error)
        }

        self.task?.resume()
    }

    public func cancel() {

        task?.cancel()
    }

    public func handleNetworkResponse<T: CodableResponse>(_ response: Response) -> Result<T> {

        switch response.response?.statusCode ?? -1 {
        case 200...299:
            do {
                guard let data = response.data else { return .failure(NetworkResponse.failed) }
                let apiResponse = try JSONDecoder().decode(T.self, from: data)
                return Result.success(apiResponse)
            } catch {
                return .failure(NetworkResponse.failed)
            }

        case 401...500:
            return .failure(NetworkResponse.authenticationError)
        case 501...599:
            return .failure(NetworkResponse.badRequest)
        case 600:
            return .failure(NetworkResponse.outdated)
        default:
            return .failure(NetworkResponse.failed)
        }
    }

    fileprivate func buildRequest(from request: YMRequest) throws -> URLRequest? {

        guard let baseURL = URL(string: configuration.baseURL) else { return nil }
        var urlRequest = URLRequest(
            url: baseURL.appendingPathComponent(request.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10.0 // TODO: - Fix it
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

    fileprivate func configureParameters(
        bodyParameters: Parameters?,
        urlParameters: Parameters?,
        request: inout URLRequest
    ) throws {

        do {
            if let bodyParameters = bodyParameters {
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }

            if let urlParameters = urlParameters {
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        }
    }

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
