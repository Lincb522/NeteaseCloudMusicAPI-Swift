// NCMClient+Cloud.swift
// 云盘相关 API 接口
// 云盘歌曲列表、详情、删除、匹配、导入等

import Foundation

// MARK: - 云盘 API

extension NCMClient {

    /// 获取云盘歌曲列表
    /// - Parameters:
    ///   - limit: 每页数量，默认 30
    ///   - offset: 偏移量，默认 0
    /// - Returns: API 响应，包含云盘歌曲列表
    public func userCloud(
        limit: Int = 30,
        offset: Int = 0
    ) async throws -> APIResponse {
        let data: [String: Any] = [
            "limit": limit,
            "offset": offset,
        ]
        return try await request(
            "/api/v1/cloud/get",
            data: data
        )
    }

    /// 获取云盘歌曲详情
    /// - Parameter ids: 歌曲 ID 数组
    /// - Returns: API 响应，包含云盘歌曲详细信息
    public func userCloudDetail(ids: [Int]) async throws -> APIResponse {
        let songIds = ids.map { ["id": $0] }
        let songIdsData = try JSONSerialization.data(withJSONObject: songIds)
        let songIdsStr = String(data: songIdsData, encoding: .utf8) ?? "[]"
        let data: [String: Any] = [
            "songIds": songIdsStr,
        ]
        return try await request(
            "/api/v1/cloud/get/byids",
            data: data
        )
    }

    /// 删除云盘歌曲
    /// - Parameter ids: 歌曲 ID 数组
    /// - Returns: API 响应
    public func userCloudDel(ids: [Int]) async throws -> APIResponse {
        let data: [String: Any] = [
            "songIds": ids,
        ]
        return try await request(
            "/api/cloud/del",
            data: data
        )
    }

    /// 云盘歌曲匹配
    /// - Parameters:
    ///   - sid: 云盘歌曲 ID
    ///   - asid: 匹配目标歌曲 ID
    /// - Returns: API 响应
    public func cloudMatch(sid: Int, asid: Int) async throws -> APIResponse {
        let data: [String: Any] = [
            "sid": sid,
            "asid": asid,
        ]
        return try await request(
            "/api/cloud/user/song/match",
            data: data
        )
    }

    /// 云盘歌曲导入
    /// - Parameter songId: 歌曲 ID
    /// - Returns: API 响应
    public func cloudImport(songId: Int) async throws -> APIResponse {
        let data: [String: Any] = [
            "songId": songId,
        ]
        return try await request(
            "/api/cloud/importSong",
            data: data
        )
    }

    // MARK: - 以下为补充接口

    /// 获取云盘歌词
    /// - Parameters:
    ///   - uid: 用户 ID
    ///   - sid: 歌曲 ID
    /// - Returns: API 响应
    public func cloudLyricGet(uid: Int, sid: Int) async throws -> APIResponse {
        let data: [String: Any] = [
            "userId": uid,
            "songId": sid,
            "lv": -1,
            "kv": -1,
        ]
        return try await request("/api/cloud/lyric/get", data: data, crypto: .eapi)
    }
}
