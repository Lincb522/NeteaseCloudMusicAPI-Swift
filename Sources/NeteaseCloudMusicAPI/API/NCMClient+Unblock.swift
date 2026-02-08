// NCMClient+Unblock.swift
// 第三方解灰模块
// 支持 UNM、自定义 API、洛雪音源等多种第三方音源
// 用于获取灰色（无版权）歌曲的可用播放链接

import Foundation

// MARK: - 自定义音源协议

/// 第三方音源协议
/// 实现此协议可接入任意第三方音源（类似洛雪音乐助手的自定义音源）
public protocol NCMUnblockSource {
    /// 音源名称（用于标识和日志）
    var name: String { get }

    /// 音源支持的平台列表（如 ["qq", "kuwo", "kugou", "migu"]）
    var platforms: [String] { get }

    /// 根据歌曲信息获取可用的播放链接
    /// - Parameters:
    ///   - id: 网易云歌曲 ID
    ///   - title: 歌曲名（可选，用于跨平台搜索匹配）
    ///   - artist: 歌手名（可选，用于跨平台搜索匹配）
    ///   - album: 专辑名（可选，辅助匹配）
    ///   - quality: 期望音质（如 "128", "320", "flac"）
    /// - Returns: 匹配结果，包含播放 URL 和元信息
    func match(
        id: Int,
        title: String?,
        artist: String?,
        album: String?,
        quality: String
    ) async throws -> UnblockResult
}

/// 解灰匹配结果
public struct UnblockResult {
    /// 歌曲播放 URL
    public let url: String
    /// 实际音质
    public let quality: String
    /// 来源平台
    public let platform: String
    /// 额外信息
    public let extra: [String: Any]

    public init(url: String, quality: String = "", platform: String = "", extra: [String: Any] = [:]) {
        self.url = url
        self.quality = quality
        self.platform = platform
        self.extra = extra
    }
}

// MARK: - 内置音源实现

/// UNM (UnblockNeteaseMusic) 音源
/// 需要自行部署 UNM-Server: https://github.com/UnblockNeteaseMusic/server
public struct UNMSource: NCMUnblockSource {
    public let name = "UNM"
    public let platforms: [String]
    /// UNM 服务地址
    public let serverUrl: String

    public init(serverUrl: String, platforms: [String] = ["qq", "kuwo", "kugou", "migu"]) {
        self.serverUrl = serverUrl
        self.platforms = platforms
    }

    public func match(id: Int, title: String?, artist: String?, album: String?, quality: String) async throws -> UnblockResult {
        var urlStr = "\(serverUrl)/match?id=\(id)"
        if !platforms.isEmpty {
            urlStr += "&source=\(platforms.joined(separator: ","))"
        }
        guard let url = URL(string: urlStr) else {
            throw NCMError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let resultUrl = json["url"] as? String ?? ""
        return UnblockResult(
            url: resultUrl,
            quality: quality,
            platform: json["source"] as? String ?? "unknown",
            extra: json
        )
    }
}

/// 通用 HTTP API 音源
/// 兼容 GD Studio 等标准 HTTP 接口格式
/// 请求格式: {serverUrl}?types=url&id={id}&br={quality}
public struct HTTPAPISource: NCMUnblockSource {
    public let name: String
    public let platforms: [String]
    /// API 基础地址
    public let serverUrl: String
    /// 支持的音质列表
    public let supportedQualities: [String]

    public init(
        name: String = "HTTPAPISource",
        serverUrl: String,
        platforms: [String] = [],
        supportedQualities: [String] = ["128", "192", "320", "740", "999"]
    ) {
        self.name = name
        self.serverUrl = serverUrl
        self.platforms = platforms
        self.supportedQualities = supportedQualities
    }

    public func match(id: Int, title: String?, artist: String?, album: String?, quality: String) async throws -> UnblockResult {
        let br = supportedQualities.contains(quality) ? quality : "320"
        let urlStr = "\(serverUrl)?types=url&id=\(id)&br=\(br)"
        guard let url = URL(string: urlStr) else {
            throw NCMError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let resultUrl = json["url"] as? String ?? ""
        return UnblockResult(url: resultUrl, quality: br, platform: name, extra: json)
    }
}

/// 洛雪音乐助手兼容音源
/// 支持导入洛雪格式的自定义音源脚本配置
/// 请求格式: {serverUrl}/url/{platform}/{id}/{quality}
public struct LxMusicSource: NCMUnblockSource {
    public let name: String
    public let platforms: [String]
    /// 洛雪音源 API 地址
    public let serverUrl: String
    /// 默认搜索平台
    public let defaultPlatform: String

    public init(
        name: String = "LxMusic",
        serverUrl: String,
        platforms: [String] = ["wy", "kw", "kg", "tx", "mg"],
        defaultPlatform: String = "wy"
    ) {
        self.name = name
        self.serverUrl = serverUrl
        self.platforms = platforms
        self.defaultPlatform = defaultPlatform
    }

    public func match(id: Int, title: String?, artist: String?, album: String?, quality: String) async throws -> UnblockResult {
        // 洛雪格式: /url/{platform}/{songId}/{quality}
        let lxQuality = mapQuality(quality)
        let urlStr = "\(serverUrl)/url/\(defaultPlatform)/\(id)/\(lxQuality)"
        guard let url = URL(string: urlStr) else {
            throw NCMError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

        // 洛雪音源可能直接返回 URL 文本，也可能返回 JSON
        if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            let resultUrl = json["url"] as? String ?? json["data"] as? String ?? ""
            return UnblockResult(url: resultUrl, quality: lxQuality, platform: defaultPlatform, extra: json)
        } else if let text = String(data: data, encoding: .utf8), statusCode == 200 {
            return UnblockResult(url: text.trimmingCharacters(in: .whitespacesAndNewlines), quality: lxQuality, platform: defaultPlatform)
        }
        return UnblockResult(url: "", quality: lxQuality, platform: defaultPlatform)
    }

    /// 将通用音质映射为洛雪音质标识
    private func mapQuality(_ quality: String) -> String {
        switch quality {
        case "128": return "128k"
        case "192": return "192k"
        case "320": return "320k"
        case "740", "flac": return "flac"
        case "999": return "flac24bit"
        default: return "320k"
        }
    }
}


// MARK: - 解灰管理器

/// 第三方音源管理器
/// 管理多个音源，支持按优先级自动降级匹配
public class UnblockManager {
    /// 已注册的音源列表（按优先级排序，靠前的优先使用）
    public private(set) var sources: [NCMUnblockSource] = []

    public init() {}

    /// 注册音源
    /// - Parameter source: 音源实例
    public func register(_ source: NCMUnblockSource) {
        sources.append(source)
    }

    /// 批量注册音源
    /// - Parameter sources: 音源实例数组
    public func register(_ sources: [NCMUnblockSource]) {
        self.sources.append(contentsOf: sources)
    }

    /// 移除所有音源
    public func removeAll() {
        sources.removeAll()
    }

    /// 移除指定名称的音源
    /// - Parameter name: 音源名称
    public func remove(named name: String) {
        sources.removeAll { $0.name == name }
    }

    /// 按优先级尝试所有音源匹配歌曲
    /// - Parameters:
    ///   - id: 歌曲 ID
    ///   - title: 歌曲名（可选）
    ///   - artist: 歌手名（可选）
    ///   - album: 专辑名（可选）
    ///   - quality: 期望音质，默认 "320"
    /// - Returns: 第一个成功匹配的结果，全部失败则返回 nil
    public func match(
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        quality: String = "320"
    ) async -> UnblockResult? {
        for source in sources {
            do {
                let result = try await source.match(
                    id: id, title: title, artist: artist,
                    album: album, quality: quality
                )
                if !result.url.isEmpty {
                    return result
                }
            } catch {
                // 当前音源失败，尝试下一个
                continue
            }
        }
        return nil
    }

    /// 尝试所有音源，返回全部结果（含失败的）
    /// - Parameters:
    ///   - id: 歌曲 ID
    ///   - title: 歌曲名（可选）
    ///   - artist: 歌手名（可选）
    ///   - album: 专辑名（可选）
    ///   - quality: 期望音质，默认 "320"
    /// - Returns: 每个音源的匹配结果数组
    public func matchAll(
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        quality: String = "320"
    ) async -> [(source: String, result: Result<UnblockResult, Error>)] {
        var results: [(source: String, result: Result<UnblockResult, Error>)] = []
        for source in sources {
            do {
                let r = try await source.match(
                    id: id, title: title, artist: artist,
                    album: album, quality: quality
                )
                results.append((source: source.name, result: .success(r)))
            } catch {
                results.append((source: source.name, result: .failure(error)))
            }
        }
        return results
    }
}

// MARK: - NCMClient 解灰扩展

extension NCMClient {

    /// 使用解灰管理器匹配歌曲
    /// - Parameters:
    ///   - manager: 解灰管理器
    ///   - id: 歌曲 ID
    ///   - title: 歌曲名（可选）
    ///   - artist: 歌手名（可选）
    ///   - album: 专辑名（可选）
    ///   - quality: 期望音质，默认 "320"
    /// - Returns: API 响应，包含匹配到的歌曲 URL
    public func songUrlUnblock(
        manager: UnblockManager,
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        quality: String = "320"
    ) async throws -> APIResponse {
        guard let result = await manager.match(
            id: id, title: title, artist: artist,
            album: album, quality: quality
        ) else {
            return APIResponse(
                status: 404,
                body: ["code": 404, "msg": "所有音源均未匹配到结果"],
                cookies: []
            )
        }
        return APIResponse(
            status: 200,
            body: [
                "code": 200,
                "data": [
                    "id": id,
                    "url": result.url,
                    "quality": result.quality,
                    "platform": result.platform,
                ] as [String: Any],
            ],
            cookies: []
        )
    }

    // MARK: - 兼容旧接口（从 Misc 迁移）

    /// 歌曲解灰 - UNM 匹配（第三方服务）
    /// 通过第三方 UnblockMusic 服务匹配歌曲可用 URL
    /// - Parameters:
    ///   - id: 歌曲 ID
    ///   - source: 匹配来源（如 "qq"、"kuwo"、"kugou"、"migu" 等，可选）
    ///   - serverUrl: UNM 服务地址（如 "http://localhost:8080"），需自行部署
    /// - Returns: API 响应，包含匹配到的歌曲 URL
    /// - Note: 需要自行部署 UNM-Server，此方法仅封装 HTTP 请求
    public func songUrlMatch(id: Int, source: String? = nil, serverUrl: String) async throws -> APIResponse {
        var urlStr = "\(serverUrl)/match?id=\(id)"
        if let source = source {
            urlStr += "&source=\(source)"
        }
        guard let url = URL(string: urlStr) else {
            return APIResponse(status: 400, body: ["code": 400, "msg": "无效的 URL"], cookies: [])
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return APIResponse(status: statusCode, body: json.isEmpty ? ["code": statusCode] : json, cookies: [])
    }

    /// 歌曲解灰 - GD Studio API（第三方服务）
    /// 通过第三方 API 获取歌曲直链，默认使用 GD Studio 服务，支持替换为其他兼容源
    /// - Parameters:
    ///   - id: 歌曲 ID
    ///   - br: 音质，可选值 "128"、"192"、"320"、"740"、"999"，默认 "320"
    ///   - serverUrl: 第三方 API 基础地址，默认 "https://music-api.gdstudio.xyz/api.php"，可替换为任何兼容接口
    /// - Returns: API 响应，包含歌曲 URL
    public func songUrlNcmget(id: Int, br: String = "320", serverUrl: String = "https://music-api.gdstudio.xyz/api.php") async throws -> APIResponse {
        let validBR = ["128", "192", "320", "740", "999"]
        guard validBR.contains(br) else {
            return APIResponse(status: 400, body: ["code": 400, "msg": "无效音质参数", "allowed_values": validBR], cookies: [])
        }
        let urlStr = "\(serverUrl)?types=url&id=\(id)&br=\(br)"
        guard let url = URL(string: urlStr) else {
            return APIResponse(status: 400, body: ["code": 400, "msg": "无效的 URL"], cookies: [])
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return APIResponse(
            status: statusCode,
            body: ["code": 200, "data": ["id": id, "br": br, "url": json["url"] ?? ""]],
            cookies: []
        )
    }
}
