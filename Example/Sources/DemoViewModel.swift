// DemoViewModel.swift
// 示例应用的核心 ViewModel
// 管理 NCMClient 实例和所有 API 调用

import SwiftUI
import AVFoundation
import NeteaseCloudMusicAPI
import CoreImage.CIFilterBuiltins

@MainActor
class DemoViewModel: ObservableObject {

    // MARK: - 客户端

    private(set) var client: NCMClient

    // MARK: - 设置

    @Published var serverUrl: String = "" {
        didSet { updateClient() }
    }
    @Published var cookie: String = ""
    @Published var connectionStatus: String = "未连接"

    // MARK: - 登录

    @Published var isLoggedIn: Bool = false
    @Published var loginNickname: String = ""
    @Published var qrImage: UIImage?
    @Published var qrStatusText: String = ""
    @Published var qrPolling: Bool = false
    private var qrKey: String = ""

    // MARK: - 播放测试

    @Published var testSongId: String = "347230"
    @Published var playSongName: String = ""
    @Published var playUrl: String = ""
    @Published var playStatus: String = ""
    @Published var isPlaying: Bool = false
    @Published var isPlayLoading: Bool = false
    private var audioPlayer: AVPlayer?

    // MARK: - 搜索

    @Published var searchKeyword: String = ""
    @Published var searchResults: [[String: Any]] = []
    @Published var selectedSongLyric: String = ""
    @Published var selectedSongName: String = ""

    // MARK: - 歌单

    @Published var hotPlaylists: [[String: Any]] = []
    @Published var playlistTracks: [[String: Any]] = []
    @Published var selectedPlaylistName: String = ""

    // MARK: - 排行榜

    @Published var toplists: [[String: Any]] = []

    // MARK: - 通用状态

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 当前 Cookie 字符串（用于显示）
    var currentCookies: String {
        let cookies = client.currentCookies
        guard !cookies.isEmpty else { return "" }
        return cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }

    // MARK: - 初始化

    init() {
        self.client = NCMClient()
        print("[NCMDemo] 客户端初始化完成")
    }

    private func updateClient() {
        let url = serverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        client.serverUrl = url.isEmpty ? nil : url
        print("[NCMDemo] 服务地址更新: \(url.isEmpty ? "直连模式" : url)")
    }

    func applyCookie() {
        let trimmed = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            client.setCookie(trimmed)
            print("[NCMDemo] Cookie 已手动设置")
        }
    }

    // MARK: - 连接测试

    func testConnection() async {
        isLoading = true
        errorMessage = nil
        connectionStatus = "连接中..."
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 测试连接: /banner")

        do {
            let response = try await client.banner()
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let code = response.body["code"] as? Int, code == 200 {
                let banners = response.body["banners"] as? [[String: Any]] ?? []
                connectionStatus = "连接成功 ✅ (\(banners.count) 条 Banner)"
                print("[NCMDemo] ✅ /banner 成功 [\(ms)ms] banners=\(banners.count)")
            } else {
                connectionStatus = "连接异常: code=\(response.body["code"] ?? "未知")"
                print("[NCMDemo] ⚠️ /banner 异常 [\(ms)ms]")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            connectionStatus = "连接失败 ❌"
            errorMessage = error.localizedDescription
            print("[NCMDemo] ❌ /banner 失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    // MARK: - 二维码登录

    func startQrLogin() async {
        qrPolling = true
        qrImage = nil
        qrStatusText = "正在生成二维码..."
        errorMessage = nil
        print("[NCMDemo] ➡️ 开始二维码登录流程")

        do {
            // 1. 获取 key
            let keyResp = try await client.loginQrKey()
            let start = CFAbsoluteTimeGetCurrent()
            guard let data = keyResp.body["data"] as? [String: Any],
                  let unikey = data["unikey"] as? String else {
                qrStatusText = "获取二维码 Key 失败"
                qrPolling = false
                print("[NCMDemo] ❌ 获取 qrKey 失败: \(keyResp.body)")
                return
            }
            qrKey = unikey
            print("[NCMDemo] ✅ qrKey: \(unikey)")

            // 2. 生成二维码
            let qrResp = try await client.loginQrCreate(key: unikey, qrimg: true)
            if let qrData = qrResp.body["data"] as? [String: Any],
               let qrurl = qrData["qrurl"] as? String {
                qrImage = generateQRCode(from: qrurl)
                qrStatusText = "请使用网易云音乐 App 扫码"
                print("[NCMDemo] ✅ 二维码已生成, URL: \(qrurl)")
            } else if let qrimg = (qrResp.body["data"] as? [String: Any])?["qrimg"] as? String,
                      let imgData = Data(base64Encoded: qrimg.replacingOccurrences(of: "data:image/png;base64,", with: "")),
                      let img = UIImage(data: imgData) {
                qrImage = img
                qrStatusText = "请使用网易云音乐 App 扫码"
                print("[NCMDemo] ✅ 二维码已生成（base64 图片）")
            }

            // 3. 轮询扫码状态
            while qrPolling {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 秒
                let checkResp = try await client.loginQrCheck(key: unikey)
                let code = checkResp.body["code"] as? Int ?? 0
                let message = checkResp.body["message"] as? String ?? ""
                let elapsed = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)

                switch code {
                case 800:
                    qrStatusText = "二维码已过期，请重新生成"
                    qrPolling = false
                    print("[NCMDemo] ⚠️ 二维码过期 [\(elapsed)ms]")
                case 801:
                    qrStatusText = "等待扫码..."
                    print("[NCMDemo] ⏳ 等待扫码 [\(elapsed)ms]")
                case 802:
                    qrStatusText = "已扫码，等待确认..."
                    print("[NCMDemo] ⏳ 已扫码待确认 [\(elapsed)ms]")
                case 803:
                    qrStatusText = "登录成功！"
                    qrPolling = false
                    print("[NCMDemo] ✅ 二维码登录成功 [\(elapsed)ms]")
                    print("[NCMDemo] 📋 Cookie: \(currentCookies.prefix(100))...")
                    // 自动获取用户信息
                    await fetchLoginStatus()
                default:
                    qrStatusText = "状态: \(code) \(message)"
                    print("[NCMDemo] ❓ 未知状态 code=\(code) msg=\(message)")
                }
            }
        } catch {
            qrStatusText = "登录失败: \(error.localizedDescription)"
            qrPolling = false
            print("[NCMDemo] ❌ 二维码登录失败: \(error)")
        }
    }

    /// 获取登录状态并更新用户信息
    func fetchLoginStatus() async {
        print("[NCMDemo] ➡️ 获取登录状态")
        do {
            let resp = try await client.loginStatus()
            if let profile = resp.body["profile"] as? [String: Any],
               let nickname = profile["nickname"] as? String {
                isLoggedIn = true
                loginNickname = nickname
                print("[NCMDemo] ✅ 已登录: \(nickname)")
            } else if let account = resp.body["account"] as? [String: Any],
                      let id = account["id"] {
                isLoggedIn = true
                loginNickname = "用户 \(id)"
                print("[NCMDemo] ✅ 已登录: 用户 \(id)")
            } else {
                isLoggedIn = false
                loginNickname = ""
                print("[NCMDemo] ⚠️ 未登录")
            }
        } catch {
            print("[NCMDemo] ❌ 获取登录状态失败: \(error)")
        }
    }

    /// 退出登录
    func doLogout() async {
        print("[NCMDemo] ➡️ 退出登录")
        do {
            _ = try await client.logout()
            isLoggedIn = false
            loginNickname = ""
            qrImage = nil
            print("[NCMDemo] ✅ 已退出登录")
        } catch {
            print("[NCMDemo] ❌ 退出登录失败: \(error)")
        }
    }

    /// 生成二维码 UIImage
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - 播放测试

    func testPlaySong() async {
        guard let songId = Int(testSongId) else {
            playStatus = "请输入有效的歌曲 ID"
            return
        }
        isPlayLoading = true
        playStatus = ""
        playSongName = ""
        playUrl = ""
        print("[NCMDemo] ➡️ 播放测试: id=\(songId)")

        do {
            // 获取歌曲详情
            let detailResp = try await client.songDetail(ids: [songId])
            if let songs = detailResp.body["songs"] as? [[String: Any]],
               let song = songs.first,
               let name = song["name"] as? String {
                let artist = DemoViewModel.artistNames(from: song)
                playSongName = "\(name) - \(artist)"
                print("[NCMDemo] ✅ 歌曲: \(playSongName)")
            }

            // 获取播放链接
            let urlResp = try await client.songUrlV1(ids: [songId], level: .exhigh)
            if let data = urlResp.body["data"] as? [[String: Any]],
               let first = data.first,
               let urlStr = first["url"] as? String, !urlStr.isEmpty {
                playUrl = urlStr
                let size = first["size"] as? Int ?? 0
                let br = first["br"] as? Int ?? 0
                print("[NCMDemo] ✅ 播放链接: \(urlStr)")
                print("[NCMDemo]    码率=\(br/1000)kbps 大小=\(size/1024)KB")

                // 播放
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let playerItem = AVPlayerItem(url: URL(string: urlStr)!)
                audioPlayer = AVPlayer(playerItem: playerItem)
                audioPlayer?.play()
                isPlaying = true
                playStatus = "正在播放 (\(br/1000)kbps)"
                print("[NCMDemo] ▶️ 开始播放")
            } else {
                playStatus = "获取播放链接失败（可能需要登录或 VIP）"
                print("[NCMDemo] ⚠️ 无播放链接，可能需要登录")
            }
        } catch {
            playStatus = "播放失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 播放测试失败: \(error)")
        }
        isPlayLoading = false
    }

    func stopPlaying() {
        audioPlayer?.pause()
        audioPlayer = nil
        isPlaying = false
        playStatus = "已停止"
        print("[NCMDemo] ⏹ 停止播放")
    }

    // MARK: - 搜索

    func searchSongs() async {
        let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 搜索: \"\(keyword)\"")

        do {
            let response = try await client.cloudsearch(keywords: keyword, type: .single, limit: 20)
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let result = response.body["result"] as? [String: Any],
               let songs = result["songs"] as? [[String: Any]] {
                searchResults = songs
                print("[NCMDemo] ✅ 搜索完成 [\(ms)ms] 结果=\(songs.count)首")
            } else {
                searchResults = []
                errorMessage = "未找到结果"
                print("[NCMDemo] ⚠️ 搜索无结果 [\(ms)ms]")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            errorMessage = "搜索失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 搜索失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    func fetchLyric(songId: Int, songName: String) async {
        isLoading = true
        selectedSongName = songName
        selectedSongLyric = ""
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 获取歌词: id=\(songId) \"\(songName)\"")

        do {
            let response = try await client.lyric(id: songId)
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let lrc = response.body["lrc"] as? [String: Any],
               let lyricText = lrc["lyric"] as? String {
                selectedSongLyric = lyricText
                print("[NCMDemo] ✅ 歌词获取成功 [\(ms)ms] 长度=\(lyricText.count)字符")
            } else {
                selectedSongLyric = "暂无歌词"
                print("[NCMDemo] ⚠️ 暂无歌词 [\(ms)ms]")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            selectedSongLyric = "获取歌词失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 歌词获取失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    // MARK: - 歌单

    func fetchHotPlaylists() async {
        isLoading = true
        errorMessage = nil
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 获取热门歌单")

        do {
            let response = try await client.topPlaylist(cat: "全部", limit: 20)
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let playlists = response.body["playlists"] as? [[String: Any]] {
                hotPlaylists = playlists
                print("[NCMDemo] ✅ 热门歌单 [\(ms)ms] 数量=\(playlists.count)")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            errorMessage = "获取歌单失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 热门歌单失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    func fetchPlaylistDetail(id: Int, name: String) async {
        isLoading = true
        selectedPlaylistName = name
        playlistTracks = []
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 歌单详情: id=\(id) \"\(name)\"")

        do {
            let response = try await client.playlistDetail(id: id)
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let playlist = response.body["playlist"] as? [String: Any],
               let tracks = playlist["tracks"] as? [[String: Any]] {
                playlistTracks = Array(tracks.prefix(50))
                print("[NCMDemo] ✅ 歌单详情 [\(ms)ms] 歌曲=\(tracks.count)首")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            errorMessage = "获取歌单详情失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 歌单详情失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    // MARK: - 排行榜

    func fetchToplists() async {
        isLoading = true
        errorMessage = nil
        let start = CFAbsoluteTimeGetCurrent()
        print("[NCMDemo] ➡️ 获取排行榜")

        do {
            let response = try await client.toplist()
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let list = response.body["list"] as? [[String: Any]] {
                toplists = list
                print("[NCMDemo] ✅ 排行榜 [\(ms)ms] 数量=\(list.count)")
            }
        } catch {
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            errorMessage = "获取排行榜失败: \(error.localizedDescription)"
            print("[NCMDemo] ❌ 排行榜失败 [\(ms)ms] \(error)")
        }
        isLoading = false
    }

    // MARK: - 辅助方法

    static func artistNames(from song: [String: Any]) -> String {
        guard let artists = song["ar"] as? [[String: Any]] ?? song["artists"] as? [[String: Any]] else {
            return "未知歌手"
        }
        return artists.compactMap { $0["name"] as? String }.joined(separator: " / ")
    }

    static func albumName(from song: [String: Any]) -> String {
        if let al = song["al"] as? [String: Any] {
            return al["name"] as? String ?? ""
        }
        if let album = song["album"] as? [String: Any] {
            return album["name"] as? String ?? ""
        }
        return ""
    }
}
