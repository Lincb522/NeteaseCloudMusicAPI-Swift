// NCMClient+Unblock.swift
// 第三方解灰模块
// 支持导入 JS 音源脚本和自定义音源地址两种方式
// 用于获取灰色（无版权）歌曲的可用播放链接

import Foundation
import JavaScriptCore

// MARK: - 音源协议

/// 第三方音源协议
/// 实现此协议可接入任意第三方音源
public protocol NCMUnblockSource {
    /// 音源名称
    var name: String { get }
    /// 音源类型标识
    var sourceType: UnblockSourceType { get }
    /// 匹配歌曲，返回可用播放链接
    func match(id: Int, title: String?, artist: String?, quality: String) async throws -> UnblockResult
}

/// 音源类型
public enum UnblockSourceType: String, Codable {
    /// JS 脚本音源（导入 .js 文件）
    case jsScript = "js"
    /// 自定义 HTTP 地址音源
    case httpUrl = "http"
}

/// 解灰匹配结果
public struct UnblockResult {
    /// 歌曲播放 URL
    public let url: String
    /// 实际音质
    public let quality: String
    /// 来源平台/音源名称
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

// MARK: - JS 脚本音源

/// JS 脚本音源
/// 支持导入洛雪音乐助手格式的 JS 音源脚本文件
/// JS 脚本需导出以下函数:
/// - `getUrl(songId, quality)` 返回 `{ url: "...", quality: "..." }` 或 URL 字符串
/// - 可选: `getMusicInfo()` 返回 `{ name: "音源名", platforms: [...] }`
public class JSScriptSource: NCMUnblockSource {
    public let name: String
    public let sourceType: UnblockSourceType = .jsScript
    /// JS 脚本内容
    public let scriptContent: String
    /// JS 执行上下文
    private let context: JSContext

    /// 从 JS 脚本内容初始化
    /// - Parameters:
    ///   - name: 音源名称（若脚本中有 getMusicInfo 则自动获取）
    ///   - script: JS 脚本内容
    public init(name: String = "JS音源", script: String) {
        self.scriptContent = script
        self.context = JSContext()!

        // 注入 console.log
        let logHandler: @convention(block) (String) -> Void = { msg in
            print("[JSSource] \(msg)")
        }
        context.setObject(logHandler, forKeyedSubscript: "___log" as NSString)
        context.evaluateScript("var console = { log: ___log, warn: ___log, error: ___log };")

        // 注入 HTTP 请求能力（同步模拟，JS 中用 httpGet(url) 调用）
        let httpGet: @convention(block) (String) -> String = { urlStr in
            guard let url = URL(string: urlStr) else { return "" }
            let semaphore = DispatchSemaphore(value: 0)
            var result = ""
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    result = str
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
            return result
        }
        context.setObject(httpGet, forKeyedSubscript: "httpGet" as NSString)

        // 执行脚本
        context.evaluateScript(script)

        // 尝试从脚本获取音源名称
        if let info = context.evaluateScript("typeof getMusicInfo === 'function' ? getMusicInfo() : null"),
           !info.isNull, !info.isUndefined,
           let dict = info.toDictionary(),
           let scriptName = dict["name"] as? String {
            self.name = scriptName
        } else {
            self.name = name
        }
    }

    /// 从文件 URL 初始化
    /// - Parameters:
    ///   - name: 音源名称
    ///   - fileURL: JS 文件路径
    public convenience init(name: String = "JS音源", fileURL: URL) throws {
        let script = try String(contentsOf: fileURL, encoding: .utf8)
        self.init(name: name, script: script)
    }

    public func match(id: Int, title: String?, artist: String?, quality: String) async throws -> UnblockResult {
        // 调用 JS 的 getUrl 函数
        guard let getUrl = context.objectForKeyedSubscript("getUrl"),
              !getUrl.isUndefined else {
            throw NCMError.invalidURL
        }

        let jsResult = getUrl.call(withArguments: [id, quality])

        // 解析返回值：可能是字符串 URL 或对象 { url, quality }
        if let dict = jsResult?.toDictionary(),
           let url = dict["url"] as? String, !url.isEmpty {
            return UnblockResult(
                url: url,
                quality: dict["quality"] as? String ?? quality,
                platform: name,
                extra: dict as? [String: Any] ?? [:]
            )
        } else if let urlStr = jsResult?.toString(), !urlStr.isEmpty, urlStr != "undefined", urlStr != "null" {
            return UnblockResult(url: urlStr, quality: quality, platform: name)
        }

        return UnblockResult(url: "", quality: quality, platform: name)
    }
}

// MARK: - 自定义地址音源

/// 自定义 HTTP 地址音源
/// 支持多种常见 API 格式，自动适配返回值
public struct CustomURLSource: NCMUnblockSource {
    public let name: String
    public let sourceType: UnblockSourceType = .httpUrl
    /// API 基础地址
    public let baseURL: String
    /// URL 模板，支持占位符: {id}, {quality}, {br}
    /// 默认格式: {baseURL}?types=url&id={id}&br={quality}
    public let urlTemplate: String?

    public init(name: String = "自定义音源", baseURL: String, urlTemplate: String? = nil) {
        self.name = name
        self.baseURL = baseURL
        self.urlTemplate = urlTemplate
    }

    public func match(id: Int, title: String?, artist: String?, quality: String) async throws -> UnblockResult {
        let urlStr: String
        if let template = urlTemplate {
            // 使用自定义模板
            urlStr = template
                .replacingOccurrences(of: "{id}", with: "\(id)")
                .replacingOccurrences(of: "{quality}", with: quality)
                .replacingOccurrences(of: "{br}", with: quality)
                .replacingOccurrences(of: "{baseURL}", with: baseURL)
        } else {
            // 默认格式
            urlStr = "\(baseURL)?types=url&id=\(id)&br=\(quality)"
        }

        guard let url = URL(string: urlStr) else {
            throw NCMError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

        // 尝试解析 JSON
        if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            // 兼容多种返回格式
            let resultUrl = json["url"] as? String
                ?? json["data"] as? String
                ?? (json["data"] as? [String: Any])?["url"] as? String
                ?? ""
            return UnblockResult(url: resultUrl, quality: quality, platform: name, extra: json)
        }

        // 可能直接返回 URL 文本
        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           statusCode == 200, text.hasPrefix("http") {
            return UnblockResult(url: text, quality: quality, platform: name)
        }

        return UnblockResult(url: "", quality: quality, platform: name)
    }
}

// MARK: - 解灰管理器

/// 第三方音源管理器
/// 管理多个音源，支持按优先级自动降级匹配
public class UnblockManager {
    /// 已注册的音源列表（按优先级排序）
    public private(set) var sources: [NCMUnblockSource] = []

    public init() {}

    /// 注册音源
    public func register(_ source: NCMUnblockSource) {
        sources.append(source)
    }

    /// 批量注册音源
    public func register(_ sources: [NCMUnblockSource]) {
        self.sources.append(contentsOf: sources)
    }

    /// 移除所有音源
    public func removeAll() {
        sources.removeAll()
    }

    /// 移除指定名称的音源
    public func remove(named name: String) {
        sources.removeAll { $0.name == name }
    }

    /// 按优先级尝试所有音源匹配
    /// - Returns: 第一个成功匹配的结果，全部失败返回 nil
    public func match(
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        quality: String = "320"
    ) async -> UnblockResult? {
        for source in sources {
            do {
                let result = try await source.match(id: id, title: title, artist: artist, quality: quality)
                if !result.url.isEmpty {
                    return result
                }
            } catch {
                continue
            }
        }
        return nil
    }

    /// 尝试所有音源，返回全部结果
    public func matchAll(
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        quality: String = "320"
    ) async -> [(source: String, result: Result<UnblockResult, Error>)] {
        var results: [(source: String, result: Result<UnblockResult, Error>)] = []
        for source in sources {
            do {
                let r = try await source.match(id: id, title: title, artist: artist, quality: quality)
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
    public func songUrlUnblock(
        manager: UnblockManager,
        id: Int,
        title: String? = nil,
        artist: String? = nil,
        quality: String = "320"
    ) async throws -> APIResponse {
        guard let result = await manager.match(id: id, title: title, artist: artist, quality: quality) else {
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
}
