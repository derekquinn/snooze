import Foundation

public typealias HTTPHeaders = [String: String]
public typealias Parameters = [String: Any]
public typealias NetworkRouterCompletion = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> ()

public protocol EndPointType {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: HTTPHeaders { get }
}

protocol NetworkRouter: AnyObject {
    associatedtype EndPoint: EndPointType
    func request(_ route: EndPoint, completion: @escaping NetworkRouterCompletion)
    func cancel()
}

public protocol ParameterEncoder {
    static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum HTTPTask {
    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)
    case requestParametersAndHeaders(bodyParameters: Parameters?, urlParameters: Parameters, additionalHeaders: HTTPHeaders?)
}

public enum SnoozeError: String, Error {
    case emptyParameters = "HTTP Request parameters are nil."
    case encodingFailed = "HTTP parameter encoding failed."
    case URLNotFound = "URL is nil."
}

public struct URLParameterEncoder: ParameterEncoder {
    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        guard let url = urlRequest.url else { throw SnoozeError.URLNotFound }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: !parameters.isEmpty) {
            urlComponents.queryItems = [URLQueryItem]()

            for (name, value) in parameters {
                let queryItemValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                let queryItem = URLQueryItem(name: name, value: queryItemValue)
                urlComponents.queryItems?.append(queryItem)
            }

            urlRequest.url = urlComponents.url
        }

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded: charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
    }
}

public struct JSONParameterEncoder: ParameterEncoder {
    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = data
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            throw SnoozeError.encodingFailed
        }
    }
}
