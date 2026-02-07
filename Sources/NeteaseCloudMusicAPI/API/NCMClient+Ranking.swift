// NCMClient+Ranking.swift
// 排行榜相关 API 接口
// 排行榜、新歌榜、歌手榜等

import Foundation

// MARK: - 排行榜 API

extension NCMClient {

    /// 排行榜列表
    /// - Returns: API 响应，包含所有排行榜
    public func toplist() async throws -> APIResponse {
        return try await request(
            "/api/toplist",
            data: [:]
        )
    }

    /// 排行榜详情
    /// - Returns: API 响应，包含排行榜详细信息
    public func toplistDetail() async throws -> APIResponse {
        return try await request(
            "/api/toplist/detail",
            data: [:]
        )
    }

    /// 新歌榜
    /// - Parameter type: 新歌榜区域类型，默认 `.all`（全部）
    /// - Returns: API 响应，包含新歌列表
    public func topSong(type: TopSongType = .all) async throws -> APIResponse {
        let data: [String: Any] = [
            "areaId": type.rawValue,
            "total": true,
        ]
        return try await request(
            "/api/v1/discovery/new/songs",
            data: data
        )
    }

    /// 热门歌手
    /// - Parameters:
    ///   - limit: 每页数量，默认 50
    ///   - offset: 偏移量，默认 0
    /// - Returns: API 响应，包含热门歌手列表
    public func topArtists(
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> APIResponse {
        let data: [String: Any] = [
            "limit": limit,
            "offset": offset,
            "total": true,
        ]
        return try await request(
            "/api/artist/top",
            data: data,
            crypto: .weapi
        )
    }

    /// 歌手排行榜
    /// - Parameter type: 歌手排行榜区域类型，默认 `.zh`（华语）
    /// - Returns: API 响应，包含歌手排行榜数据
    public func toplistArtist(type: ToplistArtistType = .zh) async throws -> APIResponse {
        let data: [String: Any] = [
            "type": type.rawValue,
        ]
        return try await request(
            "/api/toplist/artist",
            data: data,
            crypto: .weapi
        )
    }

    /// 新碟上架
    /// - Parameters:
    ///   - limit: 每页数量，默认 50
    ///   - offset: 偏移量，默认 0
    ///   - area: 区域，默认 "ALL"
    ///   - type: 类型，默认 "new"
    /// - Returns: API 响应，包含新碟列表
    public func topAlbum(
        limit: Int = 50,
        offset: Int = 0,
        area: String = "ALL",
        type: String = "new"
    ) async throws -> APIResponse {
        let data: [String: Any] = [
            "limit": limit,
            "offset": offset,
            "area": area,
            "type": type,
            "total": true,
        ]
        return try await request(
            "/api/discovery/new/albums/area",
            data: data
        )
    }

    /// MV 排行
    /// - Parameters:
    ///   - limit: 每页数量，默认 30
    ///   - offset: 偏移量，默认 0
    ///   - area: 区域，默认为空字符串（全部）
    /// - Returns: API 响应，包含 MV 排行列表
    public func topMv(
        limit: Int = 30,
        offset: Int = 0,
        area: String = ""
    ) async throws -> APIResponse {
        let data: [String: Any] = [
            "limit": limit,
            "offset": offset,
            "area": area,
            "total": true,
        ]
        return try await request(
            "/api/mv/toplist",
            data: data,
            crypto: .weapi
        )
    }

    // MARK: - 以下为补充接口

    /// 排行榜详情（v2 版本）
    /// - Returns: API 响应
    public func toplistDetailV2() async throws -> APIResponse {
        return try await request("/api/toplist/detail/v2", data: [:], crypto: .weapi)
    }
}
