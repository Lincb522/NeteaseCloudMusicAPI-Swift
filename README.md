<p align="center">
  <img src="https://raw.githubusercontent.com/Lincb522/NeteaseCloudMusicAPI-Swift/main/docs/logo.svg" width="160" height="160" />
</p>

<h1 align="center">NeteaseCloudMusicAPI-Swift</h1>

<p align="center">
  <strong>基于 <a href="https://github.com/Binaryify/NeteaseCloudMusicApi">NeteaseCloudMusicApi</a> 封装 362 个接口的原生 Swift SDK</strong>
</p>

<p align="center">
  <a href="https://lincb522.github.io/NeteaseCloudMusicAPI-Swift/">文档</a> •
  <a href="#使用须知">使用须知</a> •
  <a href="#安装">安装</a> •
  <a href="#快速开始">快速开始</a> •
  <a href="#api-分类">API 分类</a> •
  <a href="#示例应用">示例应用</a> •
  <a href="#致谢">致谢</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/平台-iOS%2015+%20|%20macOS%2012+%20|%20tvOS%2015+%20|%20watchOS%208+-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/API-362%20个接口-green?style=flat-square" />
  <img src="https://img.shields.io/badge/依赖-零依赖-orange?style=flat-square" />
</p>

---

## ✨ 特性

- 🎵 **362 个 API 接口** — 完整覆盖网易云音乐全部功能
- 🔐 **四种加密模式** — WeAPI / EAPI / LinuxAPI / 明文，与官方客户端一致
- 🍎 **Apple 全系平台** — iOS / macOS / tvOS / watchOS
- 📦 **零外部依赖** — 仅使用 Foundation + CommonCrypto
- 🎯 **Swift 原生** — async/await、强类型枚举、完整中文文档注释

---

## ⚠️ 使用须知

> 本项目仅供学习使用，请尊重版权，请勿利用此项目从事商业行为或进行破坏版权行为

- 本项目需要配合 [NeteaseCloudMusicApi](https://github.com/Binaryify/NeteaseCloudMusicApi) 后端服务使用，请先自行部署后端
- 不要频繁调用登录接口，否则可能会被风控。登录状态还存在就不要重复调用登录接口
- 部分接口不能调用太频繁，否则可能会触发 503 错误或 IP 高频错误
- 建议使用二维码登录或验证码登录，密码登录可能触发安全验证
- 由于网易限制，在国外服务器上使用会受到限制（如 `460 cheating` 异常），建议在国内网络环境下使用
- 图片 URL 加上 `?param=宽y高` 可控制图片尺寸，如 `http://p4.music.126.net/xxx.jpg?param=200y200`
- 分页接口返回字段里有 `more`，`more` 为 `true` 则表示有下一页
- 需要登录的接口（如每日推荐、用户歌单等），未登录调用会返回错误码 301

---

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/NeteaseCloudMusicAPI-Swift.git", from: "1.0.0")
]
```

或在 Xcode 中：`File` → `Add Package Dependencies` → 输入仓库地址。

---

## 快速开始

首先部署 [NeteaseCloudMusicApi](https://github.com/Binaryify/NeteaseCloudMusicApi) 后端服务，然后：

```swift
import NeteaseCloudMusicAPI

// 创建客户端，指向你的后端服务
let client = NCMClient(serverUrl: "http://localhost:3000")

// 搜索歌曲
let result = try await client.cloudsearch(keywords: "周杰伦")
print(result.body)

// 获取歌曲详情
let detail = try await client.songDetail(ids: [347230])
print(detail.body)

// 获取歌词
let lyric = try await client.lyric(id: 347230)
print(lyric.body)
```

---

## 登录与 Cookie

```swift
let client = NCMClient(serverUrl: "http://localhost:3000")

// 方式一：手机号登录
let loginResult = try await client.loginCellphone(phone: "13800138000", password: "your_password")

// 方式二：二维码登录
let qrKey = try await client.loginQrKey()
let qrUrl = try await client.loginQrCreate(key: qrKey.body["unikey"] as! String)
// ... 扫码后轮询
let checkResult = try await client.loginQrCheck(key: key)

// 方式三：直接设置 Cookie
client.setCookie("MUSIC_U=xxx; __csrf=xxx")

// 查看当前 Cookie
print(client.currentCookies)
```

---

## API 分类

</text>
</invoke>

### 🔍 搜索 (8 个接口)

| 方法 | 说明 |
|------|------|
| `cloudsearch()` | 搜索（歌曲/专辑/歌手/歌单/MV/歌词等） |
| `searchDefault()` | 默认搜索关键词 |
| `searchHot()` | 热搜列表（简略） |
| `searchHotDetail()` | 热搜列表（详细） |
| `searchSuggest()` | 搜索建议 |
| `searchMultimatch()` | 搜索多重匹配 |
| `searchMatch()` | 搜索匹配 |
| `search()` | 搜索（旧版） |

### 🎵 歌曲 (26 个接口)

| 方法 | 说明 |
|------|------|
| `songDetail()` | 歌曲详情 |
| `songUrl()` | 歌曲播放地址 |
| `songUrlV1()` | 歌曲播放地址 V1 |
| `songDownloadUrl()` | 歌曲下载地址 |
| `songDownloadUrlV1()` | 歌曲下载地址 V1 |
| `lyric()` | 获取歌词 |
| `lyricNew()` | 获取歌词（新版） |
| `like()` | 红心歌曲 |
| `likelist()` | 红心歌曲列表 |
| `songLikeCheck()` | 检查是否已红心 |
| `scrobble()` | 听歌打卡 |
| `checkMusic()` | 歌曲可用性检查 |
| `topSong()` | 新歌速递 |
| `personalFm()` | 私人 FM |
| `personalFmMode()` | 私人 FM 模式 |
| `songChorus()` | 歌曲副歌片段 |
| `songDynamicCover()` | 歌曲动态封面 |
| `songWikiSummary()` | 歌曲百科摘要 |
| `songMusicDetail()` | 歌曲音质详情 |
| `songPurchased()` | 已购歌曲 |
| `songRedCount()` | 歌曲红色计数 |
| `songDownlist()` | 歌曲下载排行 |
| `songMonthdownlist()` | 歌曲月下载排行 |
| `songSingledownlist()` | 歌曲单曲下载排行 |
| `songOrderUpdate()` | 歌曲排序更新 |
| `songLyricsMark()` / `Add()` / `Del()` / `UserPage()` | 歌词标记系列 |

### 📋 歌单 (28 个接口)

| 方法 | 说明 |
|------|------|
| `playlistDetail()` | 歌单详情 |
| `playlistDetailDynamic()` | 歌单动态信息 |
| `playlistTrackAll()` | 歌单所有歌曲 |
| `playlistTracks()` | 歌单添加/删除歌曲 |
| `playlistCreate()` | 创建歌单 |
| `playlistDelete()` | 删除歌单 |
| `playlistSubscribe()` | 收藏/取消收藏歌单 |
| `playlistSubscribers()` | 歌单收藏者 |
| `topPlaylist()` | 歌单广场 |
| `topPlaylistHighquality()` | 精品歌单 |
| `playlistCatlist()` | 歌单分类 |
| `playlistHot()` | 热门歌单标签 |
| `playlistUpdate()` | 编辑歌单 |
| `playlistNameUpdate()` | 更新歌单名 |
| `playlistDescUpdate()` | 更新歌单描述 |
| `playlistTagsUpdate()` | 更新歌单标签 |
| `playlistOrderUpdate()` | 更新歌单顺序 |
| `playlistPrivacy()` | 歌单隐私设置 |
| `playlistMylike()` | 我喜欢的音乐 |
| `playlistCoverUpdate()` | 更新歌单封面 |
| `playlistImportNameTaskCreate()` | 导入歌单 |
| `playlistImportTaskStatus()` | 导入歌单状态 |
| `playlistDetailRcmdGet()` | 歌单推荐 |
| `playlistCategoryList()` | 歌单分类列表 |
| `playlistHighqualityTags()` | 精品歌单标签 |
| `playlistTrackAdd()` / `Delete()` | 歌单曲目操作 |
| `playlistUpdatePlaycount()` | 更新播放量 |
| `playlistVideoRecent()` | 歌单最近视频 |

### 👤 用户 (25 个接口)

| 方法 | 说明 |
|------|------|
| `userDetail()` | 用户详情 |
| `userDetailNew()` | 用户详情（新版） |
| `userAccount()` | 当前账号信息 |
| `userSubcount()` | 用户收藏计数 |
| `userLevel()` | 用户等级 |
| `userPlaylist()` | 用户歌单 |
| `userRecord()` | 用户听歌排行 |
| `userFollows()` | 用户关注列表 |
| `userFolloweds()` | 用户粉丝列表 |
| `userEvent()` | 用户动态 |
| `userBinding()` | 用户绑定信息 |
| `userBindingcellphone()` | 绑定手机号 |
| `userReplacephone()` | 更换手机号 |
| `userUpdate()` | 更新用户信息 |
| `userCloud()` | 云盘歌曲 |
| `userCloudDel()` | 删除云盘歌曲 |
| `userCloudDetail()` | 云盘歌曲详情 |
| `userCommentHistory()` | 用户评论历史 |
| `userDj()` | 用户电台 |
| `userAudio()` | 用户音频 |
| `userMedal()` | 用户勋章 |
| `userMutualfollowGet()` | 互相关注 |
| `userFollowMixed()` | 混合关注列表 |
| `userSocialStatus()` / `Edit()` / `Rcmd()` / `Support()` | 社交状态系列 |
| `follow()` | 关注/取消关注 |

### 🎤 歌手 (17 个接口)

| 方法 | 说明 |
|------|------|
| `artists()` | 歌手详情 |
| `artistAlbum()` | 歌手专辑 |
| `artistSongs()` | 歌手歌曲 |
| `artistTopSong()` | 歌手热门歌曲 |
| `artistDesc()` | 歌手描述 |
| `artistDetail()` | 歌手详情（新版） |
| `artistDetailDynamic()` | 歌手动态信息 |
| `artistMv()` | 歌手 MV |
| `artistNewMv()` | 歌手最新 MV |
| `artistNewSong()` | 歌手最新歌曲 |
| `artistList()` | 歌手分类列表 |
| `artistSub()` | 收藏歌手 |
| `artistSublist()` | 已收藏歌手 |
| `artistFans()` | 歌手粉丝 |
| `artistFollowCount()` | 歌手关注数 |
| `artistVideo()` | 歌手视频 |
| `toplistArtist()` | 歌手排行榜 |

### 💿 专辑 (14 个接口)

| 方法 | 说明 |
|------|------|
| `album()` | 专辑详情 |
| `albumDetailDynamic()` | 专辑动态信息 |
| `albumSub()` | 收藏专辑 |
| `albumSublist()` | 已收藏专辑 |
| `albumNewest()` | 最新专辑 |
| `albumNew()` | 新碟上架 |
| `topAlbum()` | 热门新碟 |
| `albumList()` | 专辑列表 |
| `albumListStyle()` | 专辑风格列表 |
| `albumDetail()` | 数字专辑详情 |
| `albumPrivilege()` | 专辑权限 |
| `albumSongsaleboard()` | 专辑销量榜 |
| `digitalAlbumOrdering()` | 购买数字专辑 |
| `digitalAlbumPurchased()` / `Sales()` / `Detail()` | 数字专辑系列 |

### 💬 评论 (13 个接口)

| 方法 | 说明 |
|------|------|
| `comment()` | 发表/删除/回复评论 |
| `commentNew()` | 获取评论（新版） |
| `commentHot()` | 热门评论 |
| `commentFloor()` | 楼层评论 |
| `commentLike()` | 点赞评论 |
| `commentHugList()` | 评论抱一抱列表 |
| `commentMusic()` | 歌曲评论 |
| `commentAlbum()` | 专辑评论 |
| `commentPlaylist()` | 歌单评论 |
| `commentMv()` | MV 评论 |
| `commentDj()` | 电台评论 |
| `commentVideo()` | 视频评论 |
| `commentEvent()` | 动态评论 |

### 🎬 MV / 视频 (18 个接口)

| 方法 | 说明 |
|------|------|
| `mvAll()` | 全部 MV |
| `mvFirst()` | 最新 MV |
| `mvExclusiveRcmd()` | 独家放送 |
| `mvDetail()` | MV 详情 |
| `mvDetailInfo()` | MV 点赞数等 |
| `mvUrl()` | MV 播放地址 |
| `mvSub()` | 收藏 MV |
| `mvSublist()` | 已收藏 MV |
| `topMv()` | MV 排行榜 |
| `videoDetail()` | 视频详情 |
| `videoDetailInfo()` | 视频点赞数等 |
| `videoUrl()` | 视频播放地址 |
| `videoSub()` | 收藏视频 |
| `videoGroup()` | 视频分组 |
| `videoGroupList()` | 视频分组列表 |
| `videoCategoryList()` | 视频分类列表 |
| `videoTimelineAll()` | 全部视频动态 |
| `videoTimelineRecommend()` | 推荐视频 |

### 📻 电台 / 播客 (25 个接口)

| 方法 | 说明 |
|------|------|
| `djDetail()` | 电台详情 |
| `djProgram()` | 电台节目列表 |
| `djProgramDetail()` | 节目详情 |
| `djSub()` | 订阅电台 |
| `djSublist()` | 已订阅电台 |
| `djHot()` | 热门电台 |
| `djRecommend()` | 推荐电台 |
| `djRecommendType()` | 分类推荐 |
| `djCatelist()` | 电台分类 |
| `djCategoryRecommend()` | 分类推荐电台 |
| `djCategoryExcludehot()` | 非热门分类 |
| `djRadioHot()` | 类别热门电台 |
| `djToplist()` | 电台排行榜 |
| `djToplistHours()` | 24 小时排行 |
| `djToplistNewcomer()` | 新人排行 |
| `djToplistPay()` | 付费排行 |
| `djToplistPopular()` | 最热主播 |
| `djRadioTop()` | 新晋电台榜 |
| `djProgramToplist()` | 节目排行 |
| `djProgramToplistHours()` | 24 小时节目排行 |
| `djBanner()` | 电台 Banner |
| `djSubscriber()` | 电台订阅者 |
| `djPaygift()` | 付费精选 |
| `djPersonalizeRecommend()` | 个性化推荐 |
| `djTodayPerfered()` | 今日优选 |

### 📊 排行榜 (8 个接口)

| 方法 | 说明 |
|------|------|
| `toplist()` | 所有排行榜 |
| `toplistDetail()` | 排行榜详情 |
| `toplistDetailV2()` | 排行榜详情 V2 |
| `topList()` | 排行榜歌曲 |
| `topArtists()` | 热门歌手 |
| `toplistArtist()` | 歌手排行榜 |
| `topSong()` | 新歌速递 |
| `topPlaylist()` | 歌单排行 |

### 🎁 推荐 (14 个接口)

| 方法 | 说明 |
|------|------|
| `recommendSongs()` | 每日推荐歌曲 |
| `recommendResource()` | 每日推荐歌单 |
| `recommendSongsDislike()` | 不喜欢推荐歌曲 |
| `personalized()` | 推荐歌单 |
| `personalizedNewsong()` | 推荐新歌 |
| `personalizedMv()` | 推荐 MV |
| `personalizedDjprogram()` | 推荐电台 |
| `personalizedPrivatecontent()` | 独家放送 |
| `personalizedPrivatecontentList()` | 独家放送列表 |
| `programRecommend()` | 推荐节目 |
| `historyRecommendSongs()` | 历史推荐歌曲 |
| `historyRecommendSongsDetail()` | 历史推荐详情 |
| `relatedPlaylist()` | 相关歌单 |
| `simiPlaylist()` / `Song()` / `Mv()` / `User()` | 相似推荐系列 |

### 🔑 登录认证 (11 个接口)

| 方法 | 说明 |
|------|------|
| `login()` | 邮箱登录 |
| `loginCellphone()` | 手机号登录 |
| `loginQrKey()` | 二维码 Key |
| `loginQrCreate()` | 生成二维码 |
| `loginQrCheck()` | 二维码状态 |
| `loginRefresh()` | 刷新登录 |
| `loginStatus()` | 登录状态 |
| `logout()` | 退出登录 |
| `captchaSent()` | 发送验证码 |
| `captchaVerify()` | 验证验证码 |
| `registerCellphone()` | 手机号注册 |

### 💎 VIP (20 个接口)

| 方法 | 说明 |
|------|------|
| `vipInfo()` | VIP 信息 |
| `vipInfoV2()` | VIP 信息 V2 |
| `vipGrowthpoint()` | 成长值 |
| `vipGrowthpointDetails()` | 成长值详情 |
| `vipGrowthpointGet()` | 领取成长值 |
| `vipTasks()` | VIP 任务 |
| `vipSign()` | VIP 签到 |
| `vipSignInfo()` | 签到信息 |
| `vipTimemachine()` | 时光机 |
| `yunbei()` | 云贝数量 |
| `yunbeiInfo()` | 云贝信息 |
| `yunbeiSign()` | 云贝签到 |
| `yunbeiTasks()` | 云贝任务 |
| `yunbeiTasksTodo()` | 待完成任务 |
| `yunbeiTaskFinish()` | 完成任务 |
| `yunbeiToday()` | 今日云贝 |
| `yunbeiExpense()` | 云贝支出 |
| `yunbeiReceipt()` | 云贝收入 |
| `yunbeiRcmdSong()` | 云贝推荐歌曲 |
| `yunbeiRcmdSongHistory()` | 推荐历史 |

### 📨 私信 (10 个接口)

| 方法 | 说明 |
|------|------|
| `msgPrivate()` | 私信列表 |
| `msgPrivateHistory()` | 私信历史 |
| `msgRecentcontact()` | 最近联系人 |
| `msgComments()` | 评论消息 |
| `msgForwards()` | 转发消息 |
| `msgNotices()` | 通知消息 |
| `sendText()` | 发送文字 |
| `sendSong()` | 发送歌曲 |
| `sendAlbum()` | 发送专辑 |
| `sendPlaylist()` | 发送歌单 |

### ☁️ 云盘 (6 个接口)

| 方法 | 说明 |
|------|------|
| `cloudUploadCheck()` | 上传检查 |
| `cloudUploadInfo()` | 上传信息提交 |
| `cloudPub()` | 云盘发布 |
| `cloudImport()` | 云盘导入 |
| `cloudMatch()` | 云盘歌曲匹配 |
| `cloudLyricGet()` | 云盘歌词 |

### 🔧 其他 (119 个接口)

包含 Banner、一起听、听歌足迹、音乐人、粉丝中心、曲风、UGC 百科、声音/播客、广播电台、动态、话题、Mlog、乐谱、首页、第三方解灰等。

---

## 第三方解灰

```swift
// UNM 解灰（需自部署 UNM-Server）
let result = try await client.songUrlMatch(
    id: 347230,
    source: "qq",
    serverUrl: "http://localhost:8080"
)

// GD Studio 解灰（支持替换第三方源）
let result = try await client.songUrlNcmget(id: 347230, br: "320")

// 使用自定义源
let result = try await client.songUrlNcmget(
    id: 347230,
    serverUrl: "https://my-music-api.example.com/api.php"
)
```

---

## 示例应用

`Example/` 目录包含一个完整的 iOS SwiftUI 示例应用，附带标准 Xcode 工程文件，支持免签真机调试：

```bash
cd Example
open NCMDemo.xcodeproj
```

在 Xcode 中选择你的 iPhone，直接 `Cmd+R` 运行即可（免费 Apple ID 即可真机调试）。

功能包括：
- ⚙️ 设置 — 配置后端服务地址、Cookie、连接测试
- 🔍 搜索 — 搜索歌曲 + 歌词展示
- 📋 歌单 — 热门歌单浏览 + 歌曲列表
- 📊 排行榜 — 全部排行榜网格展示

---

## 架构设计

```
┌─────────────────────────────────────────────┐
│                  NCMClient                   │
│          (面向用户的统一入口)                   │
│                                              │
│  ┌─ serverUrl? ──→ 后端代理模式 (HTTP POST)   │
│  └─ nil ─────────→ 直连加密模式 ↓             │
├──────────────────────────────────────────────┤
│              RequestClient                    │
│     (URL 构建 · 加密分发 · HTTP 执行)          │
├──────────┬───────────┬───────────────────────┤
│CryptoEngine│SessionManager│   NCMConstants    │
│ AES-CBC    │ Cookie 管理  │   密钥 · 域名     │
│ AES-ECB    │ 设备元数据   │   公钥 · 常量     │
│ RSA        │ UA 选择      │                   │
│ MD5        │ EAPI Header  │                   │
└──────────┴───────────┴───────────────────────┘
```

### 三层架构

| 层级 | 模块 | 职责 |
|------|------|------|
| **加密层** | `CryptoEngine` | AES-CBC/ECB 加解密、RSA 无填充加密、MD5 哈希 |
| **网络层** | `RequestClient` | URL 路径重写、加密分发、HTTP POST、响应解密 |
| **会话层** | `SessionManager` | Cookie 管理、设备元数据、UA 选择、EAPI Header |
| **入口层** | `NCMClient` | 362 个 API 方法、后端代理路由、Cookie 设置 |

### API 扩展文件

| 文件 | 接口数 | 覆盖范围 |
|------|--------|----------|
| `NCMClient+Song.swift` | 26 | 歌曲、歌词、FM、红心 |
| `NCMClient+Playlist.swift` | 28 | 歌单 CRUD、收藏、导入 |
| `NCMClient+User.swift` | 25 | 用户信息、云盘、关注 |
| `NCMClient+DJ.swift` | 25 | 电台、播客、节目 |
| `NCMClient+VIP.swift` | 20 | VIP、云贝、签到 |
| `NCMClient+MV.swift` | 18 | MV、视频 |
| `NCMClient+Artist.swift` | 17 | 歌手信息、排行 |
| `NCMClient+Album.swift` | 14 | 专辑、数字专辑 |
| `NCMClient+Recommend.swift` | 14 | 推荐、个性化 |
| `NCMClient+Comment.swift` | 13 | 评论 CRUD |
| `NCMClient+Auth.swift` | 11 | 登录、注册、验证 |
| `NCMClient+Message.swift` | 10 | 私信、通知 |
| `NCMClient+Search.swift` | 8 | 搜索、热搜 |
| `NCMClient+Ranking.swift` | 8 | 排行榜 |
| `NCMClient+Cloud.swift` | 6 | 云盘上传 |
| `NCMClient+Misc.swift` | 119 | 其他全部接口 |

---

## 项目结构

```
NeteaseCloudMusicAPI-Swift/
├── Package.swift
├── Sources/NeteaseCloudMusicAPI/
│   ├── NCMClient.swift              # 主客户端入口
│   ├── API/                         # 362 个 API 方法（16 个扩展文件）
│   ├── Crypto/CryptoEngine.swift    # 加密引擎
│   ├── Network/RequestClient.swift  # HTTP 请求客户端
│   ├── Session/SessionManager.swift # 会话管理
│   └── Models/                      # 枚举、常量、错误、响应类型
└── Example/                         # SwiftUI 示例应用
```

---

## 致谢

本项目的灵感和 API 参考来自以下优秀的开源项目：

- [Binaryify/NeteaseCloudMusicApi](https://github.com/Binaryify/NeteaseCloudMusicApi) — 网易云音乐 Node.js API 服务，本项目的核心参考，364 个模块完整移植为原生 Swift
- [darknessomi/musicbox](https://github.com/darknessomi/musicbox) — 网易云音乐命令行客户端，加密算法参考
- [disoul/electron-cloud-music](https://github.com/nicerloop/electron-cloud-music) — 网易云音乐 Electron 客户端
- [sqaiyan/netmusic-node](https://github.com/sqaiyan/netmusic-node) — 网易云音乐 Node.js API 封装
- [UnblockNeteaseMusic](https://github.com/UnblockNeteaseMusic/server) — 解锁网易云音乐灰色歌曲，第三方解灰功能参考

感谢以上项目的作者和贡献者们。

---

## 许可证

MIT License
