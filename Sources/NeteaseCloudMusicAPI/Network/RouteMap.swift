// RouteMap.swift
// API 路径 → Node 后端路由映射表
// 用于后端代理模式下，将 SDK 的网易云原始 API 路径转换为旧版 Node 后端的路由格式
//
// 旧版 Node 后端（NeteaseCloudMusicApiEnhanced）的路由规则：
// - 模块文件名去掉 .js，下划线替换为 /
// - 例如 banner.js → /banner, login_qr_key.js → /login/qr/key
// - 每个模块内部再调用真正的网易云 API 路径
// - SDK 需要反向映射：网易云 API 路径 → Node 后端路由

import Foundation

// MARK: - 路由映射

/// Node 后端路由映射工具
/// 将网易云原始 API 路径转换为旧版 NeteaseCloudMusicApi 后端的路由
enum RouteMap {

    // MARK: - 静态路由映射表

    /// 精确匹配的静态路由映射
    /// key: 网易云原始 API 路径, value: Node 后端路由
    static let staticRoutes: [String: String] = [
        // 认证
        "/api/w/login": "/login",
        "/api/w/login/cellphone": "/login/cellphone",
        "/api/login/qrcode/unikey": "/login/qr/key",
        "/api/login/qrcode/client/login": "/login/qr/check",
        "/api/login/token/refresh": "/login/refresh",
        "/api/w/nuser/account/get": "/login/status",
        "/api/logout": "/logout",
        "/api/sms/captcha/sent": "/captcha/sent",
        "/api/sms/captcha/verify": "/captcha/verify",
        "/api/w/register/cellphone": "/register/cellphone",
        "/api/register/anonimous": "/register/anonimous",
        "/api/cellphone/existence/check": "/cellphone/existence/check",
        "/api/nickname/duplicated": "/nickname/check",
        "/api/user/replaceCellphone": "/user/replacephone",
        "/api/user/bindingCellphone": "/user/bindingcellphone",

        // 用户
        "/api/nuser/account/get": "/user/account",
        "/api/user/level": "/user/level",
        "/api/subcount": "/user/subcount",
        "/api/user/playlist": "/user/playlist",
        "/api/user/profile/update": "/user/update",
        "/api/user/setting": "/setting",
        "/api/user/mutualfollow/get": "/user/mutualfollow/get",
        "/api/user/follow/users/mixed/get/v2": "/user/follow/mixed",
        "/api/medal/user/page": "/user/medal",
        "/api/social/user/status": "/user/social/status",
        "/api/social/user/status/edit": "/user/social/status/edit",
        "/api/social/user/status/rcmd": "/user/social/status/rcmd",
        "/api/social/user/status/support": "/user/social/status/support",
        "/api/user/getUserIds": "/get/userids",
        "/api/user/avatar/upload/v1": "/avatar/upload",
        "/api/user/comment/history": "/user/comment/history",  // comment_user_comment_history 模块不存在，但 SDK 可能用到

        // 歌曲
        "/api/v3/song/detail": "/song/detail",
        "/api/song/enhance/player/url": "/song/url",
        "/api/song/enhance/player/url/v1": "/song/url/v1",
        "/api/song/enhance/download/url": "/song/download/url",
        "/api/song/enhance/download/url/v1": "/song/download/url/v1",
        "/api/song/lyric": "/lyric",
        "/api/song/lyric/v1": "/lyric/new",
        "/api/check/music": "/check/music",  // 可能不存在
        "/api/song/like/check": "/song/like/check",
        "/api/song/like/get": "/likelist",
        "/api/radio/like": "/like",
        "/api/song/chorus": "/song/chorus",
        "/api/song/red/count": "/song/red/count",
        "/api/song/music/detail/get": "/song/music/detail",
        "/api/song/play/about/block/page": "/song/wiki/summary",
        "/api/song/play/lyrics/mark/song": "/song/lyrics/mark",
        "/api/song/play/lyrics/mark/add": "/song/lyrics/mark/add",
        "/api/song/play/lyrics/mark/del": "/song/lyrics/mark/del",
        "/api/song/play/lyrics/mark/user/page": "/song/lyrics/mark/user/page",
        "/api/songplay/dynamic-cover": "/song/dynamic/cover",
        "/api/member/song/downlist": "/song/downlist",
        "/api/member/song/monthdownlist": "/song/monthdownlist",
        "/api/member/song/singledownlist": "/song/singledownlist",
        "/api/single/mybought/song/list": "/song/purchased",
        "/api/scrobble": "/scrobble",  // 可能不存在
        "/api/song/enhance/play/mv/url": "/mv/url",
        "/api/playmode/intelligence/list": "/playmode/intelligence/list",
        "/api/playmode/song/vector/get": "/playmode/song/vector",
        "/api/song/order/update": "/song/order/update",  // 注意：后端 playlist_tracks 也用这个 API

        // 专辑
        "/api/album/new": "/album/new",
        "/api/discovery/newAlbum": "/album/newest",
        "/api/album/sublist": "/album/sublist",
        "/api/album/detail/dynamic": "/album/detail/dynamic",
        "/api/album/privilege": "/album/privilege",
        "/api/discovery/new/albums/area": "/top/album",
        "/api/vipmall/albumproduct/list": "/album/list",
        "/api/vipmall/appalbum/album/style": "/album/list/style",
        "/api/vipmall/albumproduct/detail": "/digitalAlbum/detail",
        "/api/ordering/web/digital": "/digitalAlbum/ordering",
        "/api/digitalAlbum/purchased": "/digitalAlbum/purchased",
        "/api/vipmall/albumproduct/album/query/sales": "/digitalAlbum/sales",

        // 歌单
        "/api/playlist/create": "/playlist/create",
        "/api/playlist/remove": "/playlist/delete",
        "/api/playlist/update/name": "/playlist/name/update",
        "/api/playlist/desc/update": "/playlist/desc/update",
        "/api/playlist/tags/update": "/playlist/tags/update",
        "/api/playlist/order/update": "/playlist/order/update",
        "/api/playlist/cover/update": "/playlist/cover/update",
        "/api/playlist/update/privacy": "/playlist/privacy",
        "/api/playlist/update/playcount": "/playlist/update/playcount",
        "/api/playlist/subscribers": "/playlist/subscribers",
        "/api/playlist/detail/dynamic": "/playlist/detail/dynamic",
        "/api/playlist/detail/rcmd/get": "/playlist/detail/rcmd/get",
        "/api/playlist/catalogue": "/playlist/catlist",
        "/api/playlist/category/list": "/playlist/category/list",
        "/api/playlist/hottags": "/playlist/hot",
        "/api/playlist/highquality/tags": "/playlist/highquality/tags",
        "/api/playlist/highquality/list": "/top/playlist/highquality",
        "/api/playlist/list": "/top/playlist",
        "/api/playlist/track/add": "/playlist/track/add",
        "/api/playlist/track/delete": "/playlist/track/delete",
        "/api/playlist/manipulate/tracks": "/playlist/tracks",
        "/api/playlist/video/recent": "/playlist/video/recent",
        "/api/playlist/import/name/task/create": "/playlist/import/name/task/create",
        "/api/playlist/import/task/status/v2": "/playlist/import/task/status",
        "/api/mlog/playlist/mylike/bytime/get": "/playlist/mylike",
        "/api/v4/detail": "/top/list",  // 注意：后端是 top_list.js
        "/api/playlist/v4/detail": "/top/list",
        "/api/v6/playlist/detail": "/playlist/track/all",

        // 搜索
        "/api/search/voice/get": "/search",
        "/api/search/get": "/search",
        "/api/cloudsearch/pc": "/cloudsearch",
        "/api/search/hot": "/search/hot",
        "/api/hotsearchlist/get": "/search/hot/detail",
        "/api/search/defaultkeyword/get": "/search/default",
        "/api/search/suggest/": "/search/suggest",
        "/api/search/match/new": "/search/match",
        "/api/search/suggest/multimatch": "/search/multimatch",

        // 评论
        "/api/resource/comment/floor/get": "/comment/floor",
        "/api/v2/resource/comments": "/comment/new",
        "/api/v2/resource/comments/hug/list": "/comment/hug/list",
        "/api/v2/resource/comments/hug/listener": "/hug/comment",

        // 歌手
        "/api/v1/artist/list": "/artist/list",
        "/api/v1/artist/songs": "/artist/songs",
        "/api/artist/top/song": "/artist/top/song",
        "/api/artist/introduction": "/artist/desc",
        "/api/artist/head/info/get": "/artist/detail",
        "/api/artist/detail/dynamic": "/artist/detail/dynamic",
        "/api/artist/fans/get": "/artist/fans",
        "/api/artist/follow/count/get": "/artist/follow/count",
        "/api/artist/mvs": "/artist/mv",
        "/api/artist/sublist": "/artist/sublist",
        "/api/artist/top": "/top/artists",
        "/api/mlog/artist/video": "/artist/video",
        "/api/sub/artist/new/works/song/list": "/artist/new/song",
        "/api/sub/artist/new/works/mv/list": "/artist/new/mv",

        // MV / 视频
        "/api/mv/all": "/mv/all",
        "/api/mv/first": "/mv/first",
        "/api/mv/exclusive/rcmd": "/mv/exclusive/rcmd",
        "/api/mv/toplist": "/top/mv",
        "/api/v1/mv/detail": "/mv/detail",
        "/api/cloudvideo/allvideo/sublist": "/mv/sublist",
        "/api/cloudvideo/v1/video/detail": "/video/detail",
        "/api/cloudvideo/playurl": "/video/url",
        "/api/cloudvideo/category/list": "/video/category/list",
        "/api/cloudvideo/group/list": "/video/group/list",
        "/api/cloudvideo/v1/allvideo/rcmd": "/related/allvideo",
        "/api/videotimeline/get": "/video/timeline/recommend",
        "/api/videotimeline/otherclient/get": "/video/timeline/all",
        "/api/videotimeline/videogroup/otherclient/get": "/video/group",
        "/api/comment/commentthread/info": "/video/detail/info",
        "/api/mlog/detail/v1": "/mlog/url",
        "/api/mlog/rcmd/feed/list": "/mlog/music/rcmd",
        "/api/mlog/video/convert/id": "/mlog/to/video",

        // 电台 / DJ
        "/api/djradio/v2/get": "/dj/detail",
        "/api/djradio/hot/v1": "/dj/hot",
        "/api/djradio/hot": "/dj/radio/hot",
        "/api/djradio/recommend/v1": "/dj/recommend",
        "/api/djradio/recommend": "/dj/recommend/type",
        "/api/djradio/personalize/rcmd": "/dj/personalize/recommend",
        "/api/djradio/category/get": "/dj/catelist",
        "/api/djradio/category/excludehot": "/dj/category/excludehot",
        "/api/djradio/home/category/recommend": "/dj/category/recommend",
        "/api/djradio/banner/get": "/dj/banner",
        "/api/djradio/home/paygift/list": "/dj/paygift",
        "/api/djradio/home/today/perfered": "/dj/today/perfered",
        "/api/djradio/toplist": "/dj/toplist",
        "/api/djradio/toplist/pay": "/dj/toplist/pay",
        "/api/dj/toplist/hours": "/dj/toplist/hours",
        "/api/dj/toplist/newcomer": "/dj/toplist/newcomer",
        "/api/dj/toplist/popular": "/dj/toplist/popular",
        "/api/djradio/subscriber": "/dj/subscriber",
        "/api/djradio/get/subed": "/dj/sublist",
        "/api/dj/program/byradio": "/dj/program",
        "/api/dj/program/detail": "/dj/program/detail",
        "/api/program/toplist/v1": "/dj/program/toplist",
        "/api/djprogram/toplist/hours": "/dj/program/toplist/hours",
        "/api/program/recommend/v1": "/program/recommend",
        "/api/expert/worksdata/works/top/get": "/djRadio/top",
        "/api/djradio/get/byuser": "/user/audio",

        // 推荐 / 个性化
        "/api/v1/discovery/recommend/resource": "/recommend/resource",
        "/api/v3/discovery/recommend/songs": "/recommend/songs",
        "/api/v2/discovery/recommend/dislike": "/recommend/songs/dislike",
        "/api/personalized/playlist": "/personalized",
        "/api/personalized/newsong": "/personalized/newsong",
        "/api/personalized/mv": "/personalized/mv",
        "/api/personalized/djprogram": "/personalized/djprogram",
        "/api/personalized/privatecontent": "/personalized/privatecontent",
        "/api/v2/privatecontent/list": "/personalized/privatecontent/list",
        "/api/v2/banner/get": "/banner",
        "/api/homepage/dragon/ball/static": "/homepage/dragon/ball",
        "/api/homepage/block/page": "/starpick/comments/summary",
        "/api/discovery/recommend/songs/history/recent": "/history/recommend/songs",
        "/api/discovery/recommend/songs/history/detail": "/history/recommend/songs/detail",
        "/api/aidj/content/rcmd/info": "/aidj/content/rcmd",

        // 排行榜
        "/api/toplist": "/toplist",
        "/api/toplist/artist": "/toplist/artist",
        "/api/toplist/detail": "/toplist/detail",
        "/api/toplist/detail/v2": "/toplist/detail/v2",
        "/api/v1/discovery/new/songs": "/top/song",

        // 相似推荐
        "/api/discovery/simiArtist": "/simi/artist",
        "/api/discovery/simiMV": "/simi/mv",
        "/api/discovery/simiPlaylist": "/simi/playlist",
        "/api/v1/discovery/simiSong": "/simi/song",
        "/api/discovery/simiUser": "/simi/user",

        // 云盘
        "/api/v1/cloud/get": "/user/cloud",
        "/api/v1/cloud/get/byids": "/user/cloud/detail",
        "/api/cloud/del": "/user/cloud/del",
        "/api/cloud/upload/check": "/cloud",
        "/api/cloud/upload/check/v2": "/cloud/import",
        "/api/cloud/user/song/match": "/cloud/match",
        "/api/cloud/lyric/get": "/cloud/lyric/get",
        "/api/upload/cloud/info/v2": "/cloud",
        "/api/cloud/pub/v2": "/cloud",
        "/api/cloud/user/song/import": "/cloud/import",

        // 私信
        "/api/msg/private/users": "/msg/private",
        "/api/msg/private/history": "/msg/private/history",
        "/api/msg/notices": "/msg/notices",
        "/api/msg/recentcontact/get": "/msg/recentcontact",
        "/api/msg/private/send": "/send/text",
        "/api/forwards/get": "/msg/forwards",

        // 动态 / 事件
        "/api/v1/event/get": "/event",
        "/api/event/delete": "/event/del",
        "/api/event/forward": "/event/forward",
        "/api/share/friends/resource": "/share/resource",

        // VIP
        "/api/music-vip-membership/front/vip/info": "/vip/info",
        "/api/music-vip-membership/client/vip/info": "/vip/info/v2",
        "/api/vipnewcenter/app/level/task/list": "/vip/tasks",
        "/api/vipnewcenter/app/level/growhpoint/basic": "/vip/growthpoint",
        "/api/vipnewcenter/app/level/growth/details": "/vip/growthpoint/details",
        "/api/vipnewcenter/app/level/task/reward/get": "/vip/growthpoint/get",
        "/api/vipnewcenter/app/user/sign/info": "/vip/sign/info",
        "/api/vip-center-bff/task/sign": "/vip/sign",
        "/api/vipmusic/newrecord/weekflow": "/vip/timemachine",

        // 云贝
        "/api/point/signed/get": "/yunbei",
        "/api/point/today/get": "/yunbei/today",
        "/api/v1/user/info": "/yunbei/info",
        "/api/pointmall/user/sign": "/yunbei/sign",
        "/api/point/expense": "/yunbei/expense",
        "/api/point/receipt": "/yunbei/receipt",
        "/api/usertool/task/list/all": "/yunbei/tasks",
        "/api/usertool/task/point/receive": "/yunbei/task/finish",
        "/api/usertool/task/todo/query": "/yunbei/tasks/todo",
        "/api/yunbei/rcmd/song/submit": "/yunbei/rcmd/song",
        "/api/yunbei/rcmd/song/history/list": "/yunbei/rcmd/song/history",

        // 音乐人
        "/api/cloudbean/get": "/musician/cloudbean",
        "/api/nmusician/workbench/mission/reward/obtain/new": "/musician/cloudbean/obtain",
        "/api/creator/musician/statistic/data/overview/get": "/musician/data/overview",
        "/api/creator/musician/play/count/statistic/data/trend/get": "/musician/play/trend",
        "/api/creator/user/access": "/musician/sign",
        "/api/nmusician/workbench/mission/cycle/list": "/musician/tasks",
        "/api/nmusician/workbench/mission/stage/list": "/musician/tasks/new",

        // 签到 / 日常
        "/api/point/dailyTask": "/daily_signin",
        "/api/act/modules/signin/v2/progress": "/signin/progress",
        "/api/sign/happy/info": "/sign/happy/info",

        // 风格
        "/api/tag/list/get": "/style/list",
        "/api/style-tag/home/head": "/style/detail",
        "/api/style-tag/home/song": "/style/song",
        "/api/style-tag/home/album": "/style/album",
        "/api/style-tag/home/artist": "/style/artist",
        "/api/style-tag/home/playlist": "/style/playlist",
        "/api/tag/my/preference/get": "/style/preference",

        // 曲谱
        "/api/music/sheet/list/v1": "/sheet/list",
        "/api/music/sheet/preview/info": "/sheet/preview",

        // 一起听
        "/api/listen/together/room/create": "/listentogether/room/create",
        "/api/listen/together/room/check": "/listentogether/room/check",
        "/api/listen/together/status/get": "/listentogether/status",
        "/api/listen/together/play/invitation/accept": "/listentogether/accept",
        "/api/listen/together/end/v2": "/listentogether/end",
        "/api/listen/together/heartbeat": "/listentogether/heatbeat",
        "/api/listen/together/play/command/report": "/listentogether/play/command",
        "/api/listen/together/sync/list/command/report": "/listentogether/sync/list/command",
        "/api/listen/together/sync/playlist/get": "/listentogether/sync/playlist/get",

        // 播客 / 声音
        "/api/voice/broadcast/category/region/get": "/broadcast/category/region/get",
        "/api/voice/broadcast/channel/list": "/broadcast/channel/list",
        "/api/voice/broadcast/channel/currentinfo": "/broadcast/channel/currentinfo",
        "/api/content/channel/collect/list": "/broadcast/channel/collect/list",
        "/api/content/interact/collect": "/broadcast/sub",
        "/api/voice/workbench/voicelist/detail": "/voicelist/detail",
        "/api/voice/workbench/voices/by/voicelist": "/voicelist/list",
        "/api/voice/workbench/voice/list": "/voicelist/list/search",
        "/api/voice/workbench/voicelist/search": "/voicelist/search",
        "/api/voice/workbench/radio/program/trans": "/voicelist/trans",
        "/api/voice/workbench/voice/detail": "/voice/detail",
        "/api/voice/lyric/get": "/voice/lyric",
        "/api/content/voice/delete": "/voice/delete",
        "/api/nos/token/alloc": "/voice/upload",
        "/api/voice/workbench/voice/batch/upload/preCheck": "/voice/upload",
        "/api/voice/workbench/voice/batch/upload/v2": "/voice/upload",

        // 听歌数据
        "/api/content/activity/listen/data/realtime/report": "/listen/data/realtime/report",
        "/api/content/activity/listen/data/report": "/listen/data/report",
        "/api/content/activity/listen/data/today/song/play/rank": "/listen/data/today/song",
        "/api/content/activity/listen/data/total": "/listen/data/total",
        "/api/content/activity/listen/data/year/report": "/listen/data/year/report",
        "/api/content/activity/music/first/listen/info": "/music/first/listen/info",

        // 最近播放
        "/api/pc/recent/listen/list": "/recent/listen/list",
        "/api/play-record/song/list": "/record/recent/song",
        "/api/play-record/album/list": "/record/recent/album",
        "/api/play-record/playlist/list": "/record/recent/playlist",
        "/api/play-record/djradio/list": "/record/recent/dj",
        "/api/play-record/newvideo/list": "/record/recent/video",
        "/api/play-record/voice/list": "/record/recent/voice",
        "/api/v1/play/record": "/user/record",

        // 话题
        "/api/act/detail": "/topic/detail",
        "/api/act/event/hot": "/topic/detail/event/hot",
        "/api/act/hot": "/hot/topic",
        "/api/topic/sublist": "/topic/sublist",

        // UGC
        "/api/rep/ugc/detail": "/ugc/detail",
        "/api/rep/ugc/song/get": "/ugc/song/get",
        "/api/rep/ugc/album/get": "/ugc/album/get",
        "/api/rep/ugc/artist/get": "/ugc/artist/get",
        "/api/rep/ugc/artist/search": "/ugc/artist/search",
        "/api/rep/ugc/mv/get": "/ugc/mv/get",
        "/api/rep/ugc/user/devote": "/ugc/user/devote",

        // 粉丝中心
        "/api/fanscenter/overview/get": "/fanscenter/overview/get",
        "/api/fanscenter/trend/list": "/fanscenter/trend/list",
        "/api/fanscenter/basicinfo/age/get": "/fanscenter/basicinfo/age/get",
        "/api/fanscenter/basicinfo/gender/get": "/fanscenter/basicinfo/gender/get",
        "/api/fanscenter/basicinfo/province/get": "/fanscenter/basicinfo/province/get",

        // 其他
        "/api/batch": "/batch",
        "/api/activate/initProfile": "/activate/init/profile",
        "/api/radio/trash/add": "/fm_trash",
        "/api/v1/radio/get": "/personal/fm/mode",
        "/api/pl/count": "/pl/count",
        "/api/feedback/weblog": "/weblog",
        "/api/lbs/countries/v1": "/countries/code/list",
        "/api/frontrisk/verify/getqrcode": "/verify/getQr",
        "/api/frontrisk/verify/qrcodestatus": "/verify/qrcodestatus",
        "/api/influencer/web/apply/threshold/detail/get": "/threshold/detail/get",
        "/api/user/creator/authinfo/get": "/creator/authinfo/get",
        "/api/comment/user/comment/history": "/user/comment/history",
        "/api/mcalendar/detail": "/calendar",
    ]


    // MARK: - 动态路由前缀规则

    /// 动态路由匹配规则
    /// 用于处理路径中包含动态参数的情况（如用户 ID、专辑 ID 等）
    /// 格式: (前缀, 后端路由, 参数名)
    /// 匹配逻辑: 如果 API 路径以前缀开头，则映射到对应的后端路由，
    /// 并将前缀之后的路径部分作为指定参数名注入到请求参数中
    private static let dynamicRoutes: [(prefix: String, route: String, paramName: String?)] = [
        // /api/v1/album/{id} → /album, 提取 id
        ("/api/v1/album/", "/album", "id"),
        // /api/v1/artist/{id} → /artists, 提取 id
        ("/api/v1/artist/", "/artists", "id"),
        // /api/artist/albums/{id} → /artist/album, 提取 id
        ("/api/artist/albums/", "/artist/album", "id"),
        // /api/v1/user/detail/{uid} → /user/detail, 提取 uid
        ("/api/v1/user/detail/", "/user/detail", "uid"),
        // /api/w/v1/user/detail/{uid} → /user/detail/new, 提取 uid
        ("/api/w/v1/user/detail/", "/user/detail/new", "uid"),
        // /api/user/getfollows/{uid} → /user/follows, 提取 uid
        ("/api/user/getfollows/", "/user/follows", "uid"),
        // /api/user/getfolloweds/{uid} → /user/followeds, 提取 uid
        ("/api/user/getfolloweds/", "/user/followeds", "uid"),
        // /api/v1/user/bindings/{uid} → /user/binding, 提取 uid
        ("/api/v1/user/bindings/", "/user/binding", "uid"),
        // /api/v1/user/comments/{uid} → /msg/comments, 提取 uid
        ("/api/v1/user/comments/", "/msg/comments", "uid"),
        // /api/event/get/{uid} → /user/event, 提取 uid
        ("/api/event/get/", "/user/event", "uid"),
        // /api/dj/program/{uid} → /user/dj, 提取 uid
        ("/api/dj/program/", "/user/dj", "uid"),
        // /api/feealbum/songsaleboard/{type}/type → /album/songsaleboard, 提取 type
        ("/api/feealbum/songsaleboard/", "/album/songsaleboard", "type"),
        // /api/activity/summary/annual/ → /summary/annual, 提取 year
        ("/api/activity/summary/annual/", "/summary/annual", "year"),

        // 订阅/取消订阅操作（sub/unsub）— 无需提取路径参数
        ("/api/album/sub", "/album/sub", nil),
        ("/api/album/unsub", "/album/sub", nil),
        ("/api/artist/sub", "/artist/sub", nil),
        ("/api/artist/unsub", "/artist/sub", nil),
        ("/api/djradio/sub", "/dj/sub", nil),
        ("/api/djradio/unsub", "/dj/sub", nil),
        ("/api/mv/sub", "/mv/sub", nil),
        ("/api/mv/unsub", "/mv/sub", nil),
        ("/api/cloudvideo/video/sub", "/video/sub", nil),
        ("/api/cloudvideo/video/unsub", "/video/sub", nil),
        ("/api/playlist/subscribe", "/playlist/subscribe", nil),
        ("/api/playlist/unsubscribe", "/playlist/subscribe", nil),

        // 关注/取消关注 — /api/user/follow/{id}, 提取 id
        ("/api/user/follow/", "/follow", "id"),
        ("/api/user/delfollow/", "/follow", "id"),

        // 评论相关 — 提取 id
        ("/api/v1/resource/comments/R_SO_4_", "/comment/music", "id"),
        ("/api/v1/resource/comments/A_PL_0_", "/comment/playlist", "id"),
        ("/api/v1/resource/comments/R_AL_3_", "/comment/album", "id"),
        ("/api/v1/resource/comments/R_MV_5_", "/comment/mv", "id"),
        ("/api/v1/resource/comments/A_DJ_1_", "/comment/dj", "id"),
        ("/api/v1/resource/comments/R_VI_62_", "/comment/video", "id"),
        ("/api/v1/resource/comments/", "/comment/event", "id"),
        ("/api/v1/resource/hotcomments/", "/comment/hot", "id"),
        // /api/v1/comment/{like|unlike} — 无需提取
        ("/api/v1/comment/like", "/comment/like", nil),
        ("/api/v1/comment/unlike", "/comment/like", nil),
        // /api/resource/comments/{add|delete|reply} — 无需提取
        ("/api/resource/comments/add", "/comment", nil),
        ("/api/resource/comments/delete", "/comment", nil),
        ("/api/resource/comments/reply", "/comment", nil),

        // 点赞 — 无需提取
        ("/api/resource/like", "/resource/like", nil),
        ("/api/resource/unlike", "/resource/like", nil),

        // 搜索建议（带类型参数）— 提取 type（如 mobile）
        ("/api/search/suggest/", "/search/suggest", "type"),
    ]

    // MARK: - 参数转换

    /// 将 SDK 内部参数（网易云 API 格式）转换为旧版 Node 后端模块期望的参数格式
    /// 大部分接口参数兼容，只有少数需要转换
    /// 同时处理动态路由中路径参数的提取（如 /api/v1/user/detail/{uid} 中的 uid）
    /// - Parameters:
    ///   - apiPath: 网易云原始 API 路径
    ///   - data: SDK 构建的原始参数
    /// - Returns: 转换后的参数（适配后端模块的 query 格式）
    static func adaptParams(_ apiPath: String, _ data: [String: Any]) -> [String: Any] {
        var result = data

        // 1. 动态路由路径参数提取
        //    如果 apiPath 匹配某个动态路由前缀，且该规则定义了 paramName，
        //    则从路径尾部提取值注入到参数中
        for rule in dynamicRoutes {
            guard let paramName = rule.paramName, apiPath.hasPrefix(rule.prefix) else { continue }
            let tail = String(apiPath.dropFirst(rule.prefix.count))
            if !tail.isEmpty {
                // 取第一段（处理 /api/activity/summary/annual/2023/data 这种多段情况）
                let value = tail.split(separator: "/").first.map(String.init) ?? tail
                if result[paramName] == nil {
                    result[paramName] = value
                    #if DEBUG
                    print("[NCM] 路径参数提取: \(paramName)=\(value) (from \(apiPath))")
                    #endif
                }
            }
            break
        }

        // 2. 特定接口参数转换
        switch apiPath {

        // song_url_v1: SDK 传 ids="[123]", 后端期望 id=123
        case "/api/song/enhance/player/url/v1":
            if let ids = data["ids"] as? String {
                let cleaned = ids.replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                let firstId = cleaned.split(separator: ",").first.map(String.init) ?? cleaned
                result["id"] = firstId
            }

        // song_url: SDK 传 ids="[\"123\"]" + br, 后端期望 id="123,456" + br
        case "/api/song/enhance/player/url":
            if let ids = data["ids"] as? String {
                if let jsonData = ids.data(using: .utf8),
                   let arr = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
                    result["id"] = arr.joined(separator: ",")
                } else {
                    let cleaned = ids.replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                    result["id"] = cleaned
                }
            }

        // song_detail: SDK 传 c=JSON数组, 后端期望 ids="123,456"
        case "/api/v3/song/detail":
            if let c = data["c"] as? String,
               let jsonData = c.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                let ids = arr.compactMap { $0["id"] }.map { "\($0)" }
                result["ids"] = ids.joined(separator: ",")
            }

        // cloudsearch: SDK 传 s=关键词, 后端期望 keywords=关键词
        case "/api/cloudsearch/pc", "/api/search/get", "/api/search/voice/get":
            if let s = data["s"] as? String {
                result["keywords"] = s
            }

        // search_suggest: SDK 传 s, 后端期望 keywords
        case let path where path.hasPrefix("/api/search/suggest/"):
            if let s = data["s"] as? String {
                result["keywords"] = s
            }

        // 评论相关: SDK 传 rid, 后端期望 id
        case let path where path.hasPrefix("/api/v1/resource/comments/"):
            if let rid = data["rid"] {
                result["id"] = rid
            }

        default:
            break
        }

        return result
    }

    // MARK: - 路由查找

    /// 将网易云原始 API 路径转换为 Node 后端路由
    /// 优先精确匹配静态路由表，然后尝试动态路由前缀匹配
    /// 如果都没匹配到，回退到简单去掉 /api 前缀
    /// - Parameter apiPath: 网易云原始 API 路径（如 `/api/v2/banner/get`）
    /// - Returns: Node 后端路由（如 `/banner`）
    static func resolve(_ apiPath: String) -> String {
        // 1. 精确匹配静态路由
        if let route = staticRoutes[apiPath] {
            #if DEBUG
            print("[NCM] 路由映射(精确): \(apiPath) → \(route)")
            #endif
            return route
        }

        // 2. 动态路由前缀匹配（按前缀长度降序，优先匹配更具体的前缀）
        for rule in dynamicRoutes {
            if apiPath.hasPrefix(rule.prefix) {
                #if DEBUG
                print("[NCM] 路由映射(动态): \(apiPath) → \(rule.route)")
                #endif
                return rule.route
            }
        }

        // 3. 回退：去掉 /api 前缀
        var fallback = apiPath
        if fallback.hasPrefix("/api/") {
            fallback = "/" + fallback.dropFirst("/api/".count)
        }
        #if DEBUG
        print("[NCM] ⚠️ 路由映射(回退): \(apiPath) → \(fallback)")
        #endif
        return fallback
    }
}
