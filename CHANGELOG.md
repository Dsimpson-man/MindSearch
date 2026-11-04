# CHANGELOG

## v1.2.0 — AI 剪贴板模式（2026-11-05）

DeepSeek 等 AI 的 URL 带不进文字，改成「先复制关键词，再打开 App，进去粘贴」。

### 新增

- `Destination.copyOnOpen` 字段：打开目标 App 前把关键词写进 `UIPasteboard`。
- 搜索时震动提示 + toast「已复制关键词，去 XX 粘贴」，延迟 0.35s 再切到目标 App，避免提示一闪而过。
- 设置里的应用列表用 📋 图标标出剪贴板模式的应用；URL 编辑器里也有说明。

### 改动

- DeepSeek：`dpsk://chat/share?text={q}` → `dpsk://` + 剪贴板。
- Kimi / 文小言 / 通义 / 腾讯元宝 / ChatGPT：保留网页 `?q=`，额外加剪贴板兜底（网页不认参数时还能手动粘贴）。
- 豆包保持 `doubao://chat?text={q}` 直连（已确认能带文本）。

## v1.1.0 — 桌面与锁屏小组件（2026-11-04）

一次交付完整 Widget Extension，主屏三种尺寸 + 锁屏三种样式。

### 新增

- **Widget Extension target** `MindSearchWidgetExtension`，手写 pbxproj 加入双 target、依赖、Embed App Extensions、entitlements。
- **主屏小组件**
  - 小：2×2 常用应用块，点空白进主 App 输入。
  - 中：左「用（app）搜索（词）」一句话 + 右 2×2 应用块。
  - 大：4 个应用块 + 「最近搜过」一键重搜（带关键词直接跳转）。
- **锁屏小组件**：`accessoryCircular` / `accessoryRectangular` / `accessoryInline`，用 `AccessoryWidgetBackground`、系统着色，不叠加自定义纸张色。
- **App Group 共享层** `SharedData.swift`：`group.com.humengdie.JumpSearch.shared`，主 App 写、Widget 只读；老用户首次启动自动 bootstrap，不留空白小组件。
- **Deep link** `mindsearch://search?app=…&q=…&web=1`，`Info.plist` 注册 `CFBundleURLTypes`，`WidgetDeepLink.swift` 解析。
- 主 App 每次搜索 / 改设置 / 改别名 / 改 URL 都 `reloadAllTimelines()` 刷新小组件。

### 改动

- `Store` 的 `save()` / `saveSettings()` / `saveURLOverrides()` 统一调用 `publishToWidget()`。
- `ContentView` 新增 `onOpenURL` + `applyWidgetLink()`：带 q 直接跳目标 App，不带 q 填好应用名并聚焦关键词框；来自小组件时不抢默认焦点。
- `MARKETING_VERSION` 1.0 → 1.1，`CURRENT_PROJECT_VERSION` 1 → 2。
- README 补 App Group 配置说明、小组件交互表、限制说明、Roadmap。

### 已知限制

- WidgetKit 不允许 Extension 直接 `UIApplication.shared.open` 第三方 App，点击必须先唤起主 App（多一次转场）。这是系统限制，不是实现取舍。
- 锁屏点击需先解锁。
- 小组件显示的 4 个应用来自「最近使用」，暂不支持手动固定。

## v1.0.0 — 一句话搜索（2026-11-03）

- 三标签（搜索 / 想法 / 记录）、一句话输入、幽灵预览、语音输入、Metal 水滴指示器。
- 24 个应用（社交 / 购物 / 生活 / 音乐 / AI），别名与 URL 模板可编辑，网页兜底。
- 名称改为 MindSearch，生成 AppIcon。
