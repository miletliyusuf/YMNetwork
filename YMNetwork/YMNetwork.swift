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
    func cancel()
}

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

// MARK: - YMNetworkManager

public class YMNetworkManager: NetworkCommunication {

    private var task: URLSessionTask?
    private var configuration: YMNetworkConfiguartion

    public init(configuration: YMNetworkConfiguartion) {

        self.configuration = configuration
    }

    public func request<T: CodableResponse>(
        _ request: YMRequest,
        completion: @escaping YMNetworkCompletion<T>
    ) {

        let session = URLSession.shared

        // TODO: Improve
        do {
            guard let request = try self.buildRequest(from: request) else { return }
            task = session.dataTask(with: request, completionHandler: { (data, response, error) in

                guard let urlResponse = response as? HTTPURLResponse else { return }
                let result: Result<T> = self.handleNetworkResponse(
                    Response(
                        response: urlResponse,
                        data: data
                    )
                )
                completion(urlResponse, result, error)
            })
        } catch {
            completion(nil, .failure(NetworkResponse.failed), error)
        }

        self.task?.resume()
    }

    public func cancel() {

        task?.cancel()
    }

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
