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

// MARK: - YMNetwork

protocol NetworkCommunication: class {

    associatedtype EndPoint: EndPointType

    func request(_ endPoint: EndPoint, completion: @escaping YMNetworkCompletion)
    func cancel()
}

// MARK: - YMNetworkRouter

class YMNetworkRouter<EndPoint: EndPointType>: NetworkCommunication {

    private var task: URLSessionTask?

    func request(_ endPoint: EndPoint, completion: @escaping YMNetworkCompletion) {

        let session = URLSession.shared

        // TODO: Improve
        do {
            let request = try self.buildRequest(from: endPoint)
            task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                completion(data, response, error)
            })
        } catch {
            completion(nil, nil, error)
        }

        self.task?.resume()
    }

    func cancel() {

        task?.cancel()
    }

    fileprivate func buildRequest(from endPoint: EndPoint) throws -> URLRequest {

        var request = URLRequest(
            url: endPoint.baserURL.appendingPathComponent(endPoint.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10.0
        )

        request.httpMethod = endPoint.httpMethod.rawValue

        do {
            switch endPoint.task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .requestParameters(let bodyParameters, let urlParameters):
                try self.configureParameters(
                    bodyParameters: bodyParameters,
                    urlParameters: urlParameters,
                    request: &request
                )
            case .requestParametersAndHeaders(
                let bodyParameters,
                let urlParameters,
                let additionalHeaders):

                self.addAdditionalHeaders(additionalHeaders, request: &request)

                try self.configureParameters(
                    bodyParameters: bodyParameters,
                    urlParameters: urlParameters,
                    request: &request
                )
            }
            return request
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
