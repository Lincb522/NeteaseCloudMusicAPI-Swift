# Node vs Swift 接口覆盖审计（手工分析）

本审计文档用于核对 Node 版本（api-enhanced）与 Swift SDK 的接口覆盖情况。对比维度以源码为准，直接扫描 Node 模块与 Swift SDK 的 request 调用路径，避免依赖既有脚本与统计口径差异。

## 对比范围与方法

- **Node 端范围**：`module/*.js` 下所有模块，排除非业务模块 `api.js / eapi_decrypt.js / inner_version.js`
- **Swift 端范围**：`Sources/NeteaseCloudMusicAPI/API` 下所有 `public func ...` 方法
- **路径对比口径**：
  - Node：从 `request("...") / request('...') / request(\`...\`)` 中抽取 `/api/...` 路径
  - Swift：从 `request("...")` 中抽取 `/api/...` 路径
  - 对模板变量路径（`/api/xxx/${...}`、`/api/xxx/\(id)`）仅对比静态前缀
- **结论口径**：只要 Node `/api/...` 路径能在 Swift 中找到对应路径，即视为已覆盖

## 覆盖结论

- Node 端 `/api/...` 路径全部在 Swift 中存在对应调用，路径级覆盖完整
- Node 的部分“增强/代理型模块”并不调用网易云官方 `/api`，Swift 侧不以同名方法实现，而是以解灰能力提供等价功能

## 模块名与方法名差异（功能已覆盖）

以下 Node 模块在 Swift 中没有“同名 camelCase 方法”，但路径或功能已由 Swift 的其它方法覆盖：

- **cloud.js**：在 Swift 中拆分为上传流程方法
  - nosTokenAlloc / cloudUploadCheck / cloudUploadInfo / cloudPub
  - 位置： [NCMClient+Misc.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+Misc.swift#L828-L904)
- **digitalAlbum_detail.js** → `albumDetail`
  - 位置： [NCMClient+Album.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+Album.swift#L111-L122)
- **listentogether_heatbeat.js** → `listentogetherHeartbeat`
  - 位置： [NCMClient+Misc.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+Misc.swift#L124-L139)
- **login.js**（邮箱登录） → `loginEmail`
  - 位置： [NCMClient+Auth.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+Auth.swift#L44-L63)
- **rebind.js**（更换手机号） → `userReplacephone`
  - 位置： [NCMClient+User.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+User.swift#L331-L353)
- **user_bindingcellphone.js** → `userBindingCellphone`
  - 位置： [NCMClient+User.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+User.swift#L215-L234)

## 非 `/api` 模块（增强/代理能力）

以下 Node 模块不直接调用官方 `/api` 路径，属于增强或第三方能力：

- **song_url_match.js**：第三方解灰匹配，不走官方 `/api`
  - 位置： [song_url_match.js](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/module/song_url_match.js)
- **song_url_ncmget.js**：外部音源 API（GDStudio），不走官方 `/api`
  - 位置： [song_url_ncmget.js](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/module/song_url_ncmget.js)

Swift 侧通过第三方解灰能力提供等价功能与扩展点：
- 位置： [NCMClient+Unblock.swift](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API/NCMClient+Unblock.swift)

## 可复核清单

如需复核，可按以下路径进行抽样对比：

- Node 模块目录： [module](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/module)
- Swift API 目录： [Sources/NeteaseCloudMusicAPI/API](file:///Users/linchengbo/Downloads/api-enhanced-main%200201/Sources/NeteaseCloudMusicAPI/API)

## 逐模块对比清单（按模块名）

### 明细
