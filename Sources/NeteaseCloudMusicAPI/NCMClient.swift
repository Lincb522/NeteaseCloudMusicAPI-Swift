// NCMClient.swift
// 网易云音乐 API 主客户端类
// 面向用户的核心入口，封装请求层和会话管理

import Foundation

// MARK: - 主客户端

/// 网易云音乐 API 主客户端
/// 封装 RequestClient，提供统一的 API 调用入口
public class NCMClient {

    // MARK: - 内部属性

    /// 请求客户端，负责加密、HTTP 请求和响应处理
    internal let requestClient: RequestClient

    /// Node 后端服务地址（如 "http://localhost:3000"）
    /// 设置后所有请求走后端代理模式，不再由客户端加密直连网易云
    public var serverUrl: String?

    /// 网易云音乐主域名（WeAPI / LinuxAPI 使用）
    public var domain: String {
        get { requestClient.domain }
        set { requestClient.domain = newValue }
    }

    /// 网易云音乐 API 接口域名（EAPI / 明文模式使用）
    public var apiDomain: String {
        get { requestClient.apiDomain }
        set { requestClient.apiDomain = newValue }
    }

    // MARK: - 初始化

    /// 初始化客户端
    /// - Parameters:
    ///   - platformType: 平台类型，默认为 `.iphone`
    ///   - anonymousToken: 匿名令牌，默认为空字符串
    ///   - cookie: 初始 Cookie 字符串（可选），格式为 `key1=value1; key2=value2`
    ///   - domain: 主域名，默认 `https://music.163.com`
    ///   - apiDomain: API 接口域名，默认 `https://interface.music.163.com`
    ///   - serverUrl: Node 后端服务地址（可选），设置后走后端代理模式
    public init(
        platformType: PlatformType = .iphone,
        anonymousToken: String = "",
        cookie: String? = nil,
        domain: String? = nil,
        apiDomain: String? = nil,
        serverUrl: String? = nil
    ) {
        // 创建会话管理器
        let sessionManager = SessionManager(
            platformType: platformType,
            anonymousToken: anonymousToken
        )

        // 如果提供了 cookie 字符串，解析并设置到会话管理器
        if let cookie = cookie, !cookie.isEmpty {
            let parsed = NCMClient.parseCookieString(cookie)
            for (key, value) in parsed {
                sessionManager.cookies[key] = value
            }
        }

        // 创建请求客户端
        self.requestClient = RequestClient(sessionManager: sessionManager)

        // 设置自定义域名
        if let domain = domain {
            self.requestClient.domain = domain
        }
        if let apiDomain = apiDomain {
            self.requestClient.apiDomain = apiDomain
        }

        // 设置后端代理地址
        self.serverUrl = serverUrl
    }

    // MARK: - 公共接口

    /// 设置 Cookie
    /// 解析 Cookie 字符串并更新会话管理器的 Cookie 存储
    /// - Parameter cookie: Cookie 字符串，格式为 `key1=value1; key2=value2`
    public func setCookie(_ cookie: String) {
        let parsed = NCMClient.parseCookieString(cookie)
        for (key, value) in parsed {
            requestClient.sessionManager.cookies[key] = value
        }
    }

    /// 获取当前所有 Cookie
    public var currentCookies: [String: String] {
        return requestClient.sessionManager.cookies
    }

    // MARK: - 内部请求方法

    /// 发送 API 请求（供 API 扩展调用）
    /// 如果设置了 serverUrl，走后端代理模式；否则走直连加密模式
    /// - Parameters:
    ///   - uri: API 路径（如 `/api/song/detail`）
    ///   - data: 请求参数字典
    ///   - crypto: 加密模式，默认为 `.eapi`（后端代理模式下忽略）
    ///   - e_r: EAPI 响应解密标志（可选，后端代理模式下忽略）
    /// - Returns: API 响应
    /// - Throws: 加密、网络或 API 业务错误
    internal func request(
        _ uri: String,
        data: [String: Any],
        crypto: CryptoMode = .eapi,
        e_r: Bool? = nil
    ) async throws -> APIResponse {
        if let serverUrl = serverUrl {
            return try await proxyRequest(serverUrl: serverUrl, uri: uri, data: data)
        }
        let options = RequestOptions(crypto: crypto, e_r: e_r)
        return try await requestClient.request(uri: uri, data: data, options: options)
    }

    /// 后端代理模式请求
    /// 将 `/api/xxx/yyy` 转为 Node 后端路由 `/xxx/yyy`，POST 明文参数
    /// - Parameters:
    ///   - serverUrl: 后端服务地址
    ///   - uri: 原始 API 路径
    ///   - data: 请求参数字典
    /// - Returns: API 响应
    private func proxyRequest(
        serverUrl: String,
        uri: String,
        data: [String: Any]
    ) async throws -> APIResponse {
        // 将 /api/xxx/yyy 转为 Node 后端路由格式
        let route = NCMClient.apiPathToRoute(uri)
        let base = serverUrl.hasSuffix("/") ? String(serverUrl.dropLast()) : serverUrl
        let urlString = base + route

        guard let url = URL(string: urlString) else {
            throw NCMError.invalidResponse(detail: "无效的后端 URL: \(urlString)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // 附带 Cookie
        let cookieHeader = requestClient.sessionManager.buildCookieHeader(for: uri, crypto: .eapi)
        if !cookieHeader.isEmpty {
            urlRequest.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }

        // JSON 编码请求体
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        urlRequest.httpBody = jsonData

        let (responseData, response) = try await URLSession.shared.data(for: urlRequest)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 200

        // 提取 Set-Cookie
        var setCookies: [String] = []
        if let allHeaders = httpResponse?.allHeaderFields {
            for (key, value) in allHeaders {
                if "\(key)".lowercased() == "set-cookie" {
                    setCookies.append("\(value)")
                }
            }
        }

        // 更新本地 Cookie
        requestClient.sessionManager.updateCookies(from: setCookies)

        // 解析 JSON
        let body = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any]
            ?? ["_raw": String(data: responseData, encoding: .utf8) ?? ""]

        return APIResponse(status: statusCode, body: body, cookies: setCookies)
    }

    /// 将 API 路径转为 Node 后端路由
    /// `/api/song/detail` → `/song/detail`
    /// `/api/v1/discovery/simiSong` → `/simi/song`（特殊路径保持原样去掉 /api 前缀）
    static func apiPathToRoute(_ uri: String) -> String {
        // 去掉 /api 前缀
        var path = uri
        if path.hasPrefix("/api/") {
            path = "/" + path.dropFirst("/api/".count)
        }
        return path
    }

    // MARK: - 私有辅助方法

    /// 解析 Cookie 字符串为字典
    /// - Parameter cookieString: Cookie 字符串，格式为 `key1=value1; key2=value2`
    /// - Returns: Cookie 键值对字典
    private static func parseCookieString(_ cookieString: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = cookieString.split(separator: ";")
        for pair in pairs {
            let keyValue = pair.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }
            let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
            let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty {
                result[key] = value
            }
        }
        return result
    }
}
