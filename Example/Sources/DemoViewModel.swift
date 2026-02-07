// DemoViewModel.swift
// 示例应用的核心 ViewModel
// 管理 NCMClient 实例和所有 API 调用

import SwiftUI
import NeteaseCloudMusicAPI

@MainActor
class DemoViewModel: ObservableObject {

    // MARK: - 客户端

    /// 当前 API 客户端实例
    private(set) var client: NCMClient

    // MARK: - 设置

    /// 后端服务地址（留空则直连网易云）
    @Published var serverUrl: String = "" {
        didSet { updateClient() }
    }

    /// Cookie 字符串
    @Published var cookie: String = ""

    /// 连接状态信息
    @Published var connectionStatus: String = "未连接"

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

    // MARK: - 初始化

    init() {
        self.client = NCMClient()
    }

    /// 根据设置更新客户端
    private func updateClient() {
        let url = serverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        client.serverUrl = url.isEmpty ? nil : url
    }

    /// 应用 Cookie 设置
    func applyCookie() {
        let trimmed = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            client.setCookie(trimmed)
        }
    }

    /// 测试连接
    func testConnection() async {
        isLoading = true
        errorMessage = nil
        connectionStatus = "连接中..."

        do {
            let response = try await client.banner()
            if let code = response.body["code"] as? Int, code == 200 {
                let banners = response.body["banners"] as? [[String: Any]] ?? []
                connectionStatus = "连接成功 ✅ (获取到 \(banners.count) 条 Banner)"
            } else {
                connectionStatus = "连接异常: code=\(response.body["code"] ?? "未知")"
            }
        } catch {
            connectionStatus = "连接失败 ❌"
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 搜索

    /// 搜索歌曲
    func searchSongs() async {
        let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.cloudsearch(keywords: keyword, type: .single, limit: 20)
            if let result = response.body["result"] as? [String: Any],
               let songs = result["songs"] as? [[String: Any]] {
                searchResults = songs
            } else {
                searchResults = []
                errorMessage = "未找到结果"
            }
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 获取歌词
    func fetchLyric(songId: Int, songName: String) async {
        isLoading = true
        selectedSongName = songName
        selectedSongLyric = ""

        do {
            let response = try await client.lyric(id: songId)
            if let lrc = response.body["lrc"] as? [String: Any],
               let lyricText = lrc["lyric"] as? String {
                selectedSongLyric = lyricText
            } else {
                selectedSongLyric = "暂无歌词"
            }
        } catch {
            selectedSongLyric = "获取歌词失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 歌单

    /// 获取热门歌单
    func fetchHotPlaylists() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.topPlaylist(cat: "全部", limit: 20)
            if let playlists = response.body["playlists"] as? [[String: Any]] {
                hotPlaylists = playlists
            }
        } catch {
            errorMessage = "获取歌单失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 获取歌单详情中的歌曲
    func fetchPlaylistDetail(id: Int, name: String) async {
        isLoading = true
        selectedPlaylistName = name
        playlistTracks = []

        do {
            let response = try await client.playlistDetail(id: id)
            if let playlist = response.body["playlist"] as? [String: Any],
               let tracks = playlist["tracks"] as? [[String: Any]] {
                playlistTracks = Array(tracks.prefix(50))
            }
        } catch {
            errorMessage = "获取歌单详情失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 排行榜

    /// 获取所有排行榜
    func fetchToplists() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.toplist()
            if let list = response.body["list"] as? [[String: Any]] {
                toplists = list
            }
        } catch {
            errorMessage = "获取排行榜失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 辅助方法

    /// 从歌曲字典中提取歌手名
    static func artistNames(from song: [String: Any]) -> String {
        guard let artists = song["ar"] as? [[String: Any]] ?? song["artists"] as? [[String: Any]] else {
            return "未知歌手"
        }
        return artists.compactMap { $0["name"] as? String }.joined(separator: " / ")
    }

    /// 从歌曲字典中提取专辑名
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
