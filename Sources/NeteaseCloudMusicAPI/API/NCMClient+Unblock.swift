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
/// 支持导入第三方 JS 音源脚本文件
/// 自动检测脚本格式：
/// - 洛雪插件格式：依赖 globalThis.lx 事件系统，SDK 自动模拟运行环境
/// - 简单函数格式：导出 getUrl(songId, quality) 函数
public class JSScriptSource: NCMUnblockSource {
    public private(set) var name: String
    public let sourceType: UnblockSourceType = .jsScript
    /// JS 脚本内容
    public let scriptContent: String
    /// 是否为洛雪插件格式
    public let isLxFormat: Bool
    /// JS 执行上下文
    private let context: JSContext
    /// 洛雪格式：注册的请求处理器
    private var lxRequestHandler: JSValue?
    /// 洛雪格式：支持的音源列表
    private var lxSources: [String: Any] = [:]

    /// 从 JS 脚本内容初始化
    /// - Parameters:
    ///   - name: 音源名称（自动从脚本注释或 inited 事件中获取）
    ///   - script: JS 脚本内容
    public init(name: String = "JS音源", script: String) {
        self.scriptContent = script
        self.context = JSContext()!
        // 检测是否为洛雪插件格式
        self.isLxFormat = script.contains("globalThis.lx") || script.contains("EVENT_NAMES")

        // 注入 console
        let logHandler: @convention(block) (JSValue) -> Void = { msg in
            print("[JSSource] \(msg)")
        }
        let groupHandler: @convention(block) (JSValue) -> Void = { msg in
            print("[JSSource] ▸ \(msg)")
        }
        let groupEndHandler: @convention(block) () -> Void = {
            // 忽略 groupEnd
        }
        context.setObject(logHandler, forKeyedSubscript: "___log" as NSString)
        context.setObject(groupHandler, forKeyedSubscript: "___group" as NSString)
        context.setObject(groupEndHandler, forKeyedSubscript: "___groupEnd" as NSString)
        context.evaluateScript("""
            var console = {
                log: function() { var args = Array.prototype.slice.call(arguments); ___log(args.map(function(a) { try { return typeof a === 'object' ? JSON.stringify(a) : String(a); } catch(e) { return String(a); } }).join(' ')); },
                warn: function() { var args = Array.prototype.slice.call(arguments); ___log(args.map(function(a) { try { return typeof a === 'object' ? JSON.stringify(a) : String(a); } catch(e) { return String(a); } }).join(' ')); },
                error: function() { var args = Array.prototype.slice.call(arguments); ___log(args.map(function(a) { try { return typeof a === 'object' ? JSON.stringify(a) : String(a); } catch(e) { return String(a); } }).join(' ')); },
                group: function() { var args = Array.prototype.slice.call(arguments); ___group(args.join(' ')); },
                groupEnd: ___groupEnd
            };
        """)

        // 注入同步 HTTP 请求（简单格式用）
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

        // 先赋临时名称，满足 Swift 存储属性初始化要求
        self.name = name

        if isLxFormat {
            // 模拟洛雪运行环境
            self.setupLxEnvironment()
        }

        // 异常处理
        context.exceptionHandler = { _, exception in
            if let ex = exception {
                print("[JSSource] ⚠️ JS 异常: \(ex)")
            }
        }

        // 执行脚本
        context.evaluateScript(script)

        // 获取音源名称（覆盖临时值）
        // 优先从脚本注释中提取 @name
        if let range = script.range(of: #"@name\s+(.+)"#, options: .regularExpression) {
            let matched = String(script[range])
            let nameValue = matched.replacingOccurrences(of: #"@name\s+"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            if !nameValue.isEmpty {
                self.name = nameValue
            }
        }
        // 简单格式：尝试 getMusicInfo()
        if !isLxFormat {
            if let info = context.evaluateScript("typeof getMusicInfo === 'function' ? getMusicInfo() : null"),
               !info.isNull, !info.isUndefined,
               let dict = info.toDictionary(),
               let scriptName = dict["name"] as? String {
                self.name = scriptName
            }
        }
    }

    /// 从文件 URL 初始化
    public convenience init(name: String = "JS音源", fileURL: URL) throws {
        let script = try String(contentsOf: fileURL, encoding: .utf8)
        self.init(name: name, script: script)
    }

    /// 模拟洛雪 globalThis.lx 运行环境
    private func setupLxEnvironment() {
        // 存储事件处理器的容器
        context.evaluateScript("""
            var ___lxHandlers = {};
            var ___lxSources = {};
            var ___lxInited = false;
        """)

        // 注入同步 HTTP 请求（洛雪 request 格式）
        // request(url, options, callback) -> callback(err, resp)
        let lxRequest: @convention(block) (String, JSValue, JSValue) -> Void = { urlStr, optionsVal, callback in
            guard let url = URL(string: urlStr) else {
                callback.call(withArguments: ["无效 URL", NSNull()])
                return
            }
            let options = optionsVal.toDictionary() ?? [:]
            let method = (options["method"] as? String) ?? "GET"
            let headers = options["headers"] as? [String: String] ?? [:]

            var request = URLRequest(url: url)
            request.httpMethod = method
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            if let bodyData = options["body"] as? String {
                request.httpBody = bodyData.data(using: .utf8)
            }

            let semaphore = DispatchSemaphore(value: 0)
            var responseBody: Any = NSNull()
            var responseError: Any = NSNull()
            var statusCode = 200

            let task = URLSession.shared.dataTask(with: request) { data, resp, error in
                if let error = error {
                    responseError = error.localizedDescription
                } else if let data = data {
                    statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 200
                    // 尝试解析 JSON
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        responseBody = json
                    } else if let text = String(data: data, encoding: .utf8) {
                        responseBody = text
                    }
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()

            if !(responseError is NSNull) {
                callback.call(withArguments: [responseError, NSNull()])
            } else {
                // 构造 resp 对象: { statusCode, body, headers }
                let respObj: [String: Any] = [
                    "statusCode": statusCode,
                    "body": responseBody,
                    "headers": [String: String]()
                ]
                callback.call(withArguments: [NSNull(), respObj])
            }
        }
        context.setObject(lxRequest, forKeyedSubscript: "___lxRequest" as NSString)

        // on(eventName, handler) — 注册事件处理器
        let lxOn: @convention(block) (String, JSValue) -> Void = { [weak self] eventName, handler in
            self?.context.evaluateScript("___lxHandlers['\(eventName)'] = true;")
            if eventName == "request" {
                self?.lxRequestHandler = handler
            }
        }
        context.setObject(lxOn, forKeyedSubscript: "___lxOn" as NSString)

        // send(eventName, data) — 发送事件
        let lxSend: @convention(block) (String, JSValue) -> Void = { [weak self] eventName, data in
            if eventName == "inited" {
                if let dict = data.toDictionary(),
                   let sources = dict["sources"] as? [String: Any] {
                    self?.lxSources = sources
                }
            }
        }
        context.setObject(lxSend, forKeyedSubscript: "___lxSend" as NSString)

        // 注入 globalThis.lx 对象
        context.evaluateScript("""
            var globalThis = globalThis || this;
            globalThis.lx = {
                EVENT_NAMES: {
                    request: 'request',
                    inited: 'inited',
                    updateAlert: 'updateAlert'
                },
                request: ___lxRequest,
                on: ___lxOn,
                send: ___lxSend,
                utils: {},
                env: 'mobile',
                version: '2.0.0'
            };
            var lx = globalThis.lx;
        """)
    }

    public func match(id: Int, title: String?, artist: String?, quality: String) async throws -> UnblockResult {
        if isLxFormat {
            return try await matchLxFormat(id: id, title: title, artist: artist, quality: quality)
        } else {
            return try await matchSimpleFormat(id: id, quality: quality)
        }
    }

    /// 简单格式：调用 getUrl(songId, quality)
    private func matchSimpleFormat(id: Int, quality: String) async throws -> UnblockResult {
        guard let getUrl = context.objectForKeyedSubscript("getUrl"),
              !getUrl.isUndefined else {
            throw NCMError.invalidURL
        }

        let jsResult = getUrl.call(withArguments: [id, quality])

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

    /// 洛雪格式：通过事件系统调用
    private func matchLxFormat(id: Int, title: String?, artist: String?, quality: String) async throws -> UnblockResult {
        guard lxRequestHandler != nil else {
            throw NCMError.invalidURL
        }

        // 确定使用哪个 source（优先 wy/网易云）
        let sourceKey: String
        if lxSources.keys.contains("wy") {
            sourceKey = "wy"
        } else if let first = lxSources.keys.first {
            sourceKey = first
        } else {
            sourceKey = "wy"
        }

        // 映射音质：320 -> 320k, 128 -> 128k, flac 等
        let lxQuality: String
        switch quality {
        case "128": lxQuality = "128k"
        case "192": lxQuality = "192k"
        case "320": lxQuality = "320k"
        case "740", "flac": lxQuality = "flac"
        case "999": lxQuality = "flac24bit"
        default:
            if quality.hasSuffix("k") || quality.contains("flac") || quality.contains("hires") || quality.contains("atmos") || quality.contains("master") {
                lxQuality = quality
            } else {
                lxQuality = quality + "k"
            }
        }

        let songName = (title ?? "").replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: "")
        let artistName = (artist ?? "").replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: "")
        let ctx = self.context
        let handler = self.lxRequestHandler!
        let sourceName = self.name

        // 在后台线程执行，避免主线程 semaphore 死锁
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var resolvedUrl: String?
                var resolvedError: String?
                let semaphore = DispatchSemaphore(value: 0)

                let onSuccess: @convention(block) (String) -> Void = { url in
                    resolvedUrl = url
                    semaphore.signal()
                }
                let onError: @convention(block) (String) -> Void = { err in
                    resolvedError = err
                    semaphore.signal()
                }
                ctx.setObject(onSuccess, forKeyedSubscript: "___onMatchSuccess" as NSString)
                ctx.setObject(onError, forKeyedSubscript: "___onMatchError" as NSString)
                ctx.setObject(handler, forKeyedSubscript: "___lxRequestHandler" as NSString)

                let jsCall = """
                (function() {
                    try {
                        var handler = ___lxRequestHandler;
                        if (!handler) { ___onMatchError('no handler'); return; }
                        var result = handler({
                            action: 'musicUrl',
                            source: '\(sourceKey)',
                            info: {
                                type: '\(lxQuality)',
                                musicInfo: {
                                    songmid: \(id),
                                    hash: '\(id)',
                                    name: '\(songName)',
                                    singer: '\(artistName)',
                                    source: 'wy'
                                }
                            }
                        });
                        if (result && typeof result.then === 'function') {
                            result.then(function(url) {
                                ___onMatchSuccess(String(url || ''));
                            })['catch'](function(err) {
                                ___onMatchError(String(err || 'unknown'));
                            });
                        } else {
                            ___onMatchSuccess(String(result || ''));
                        }
                    } catch(e) {
                        ___onMatchError(String(e));
                    }
                })();
                """

                ctx.evaluateScript(jsCall)

                let waitResult = semaphore.wait(timeout: .now() + 30)

                // 清理
                ctx.evaluateScript("delete ___onMatchSuccess; delete ___onMatchError; delete ___lxRequestHandler;")

                if waitResult == .timedOut {
                    continuation.resume(returning: UnblockResult(url: "", quality: quality, platform: sourceName))
                    return
                }

                if let error = resolvedError {
                    continuation.resume(throwing: NCMError.networkError(statusCode: -1, message: error))
                    return
                }

                let url = resolvedUrl ?? ""
                continuation.resume(returning: UnblockResult(url: url, quality: quality, platform: sourceName))
            }
        }
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
