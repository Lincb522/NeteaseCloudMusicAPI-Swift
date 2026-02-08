# 更新日志

## 1.1.0 (2026-02-08)

### 新功能
- 解灰模块重写：支持导入第三方 JS 音源脚本文件和自定义 HTTP 地址两种方式
- JS 音源自动检测脚本格式，兼容洛雪插件格式（自动模拟 `globalThis.lx` 事件环境）
- 自定义地址音源支持 URL 模板（`{id}`、`{quality}`、`{baseURL}` 占位符）

### 修复
- VIP 任务解析：正确展平 `taskList[].taskItems[]` 子数组
- VIP 成长值：从 `data.userLevel.growthPoint` 正确读取

### 示例应用
- 解灰页面重写：JS 文件导入、文本粘贴、自定义地址添加、拖拽排序、启用/禁用开关
- VIP 任务显示增加完成状态标签
- Info.plist 改为 `NSAllowsArbitraryLoads`（第三方音源域名不可预知）

### 文档
- 解灰模块文档更新为新架构（JSScriptSource + CustomURLSource）
- ATS 注意事项补充解灰模块说明

---

## 1.0.0 (2026-02-07)

首个正式版本。

### 核心
- 362 个网易云音乐 API 原生 Swift 封装
- 四种加密模式：WeAPI / EAPI / LinuxAPI / 明文
- 后端代理模式 + 直连加密模式
- async/await、强类型枚举、完整中文注释
- Apple 全系平台：iOS 15+ / macOS 12+ / tvOS 15+ / watchOS 8+
- 零外部依赖（仅 Foundation + CommonCrypto）

### 示例应用
- 12 个测试模块：搜索、歌单、排行榜、电台、专辑、歌手、MV/视频、评论、用户、推荐、VIP/云贝、解灰
- 二维码登录、Cookie 管理、播放测试
- Xcode 16 文件系统同步组

### 文档
- Docsify 在线文档，白绿主题
- 完整 API 参考（362 个接口）
- 架构设计说明
