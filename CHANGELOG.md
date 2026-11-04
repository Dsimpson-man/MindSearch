# CHANGELOG

## v2.0.1 — 主按钮靠右（2026-11-05）

- 呼吸圆主按钮从居中移回右下角，和麦克风分居两端。

## v2.0.0 — 冥想化重构（2026-11-05）

把工具感收起来，往「安静、留白、有呼吸」的方向重做了一遍视觉和结构。

### 视觉

- 新配色：暖雾白 `#F4F1EA`、柔米 `#EDE9DF`、炭墨 `#3A3630`、雾绿 `#6B7A6A`。
- 去掉硬边框、深墨块、胶囊描边；分组靠留白和 0.5pt 细线。
- 纸纹降到几乎看不见（opacity 0.32）。
- 强制浅色模式，避免系统深色下出现半深半浅。

### 结构

- **搜索常驻**：底部只留「想法 / 记录」两个入口，搜索永远是根页面。
- 进入列表后左上角出现「‹ 搜索」返回；再点一次当前底部入口也会回到搜索。
- 底部选中态从实心墨球改成 3pt 雾绿小点。

### 交互

- 首页输入去掉括号和 `*app*` / `*关键词*` 占位符，改成「应用名 / 想搜什么」，标签与输入用细线分隔。
- 主按钮改成会缓慢呼吸的圆：待机时轻轻起伏，有关键词时收紧成雾绿实心圆。
- 所有 spring 动效换成 0.45–0.9s 的 `easeInOut`。
- 记录按「今天 / 昨天 / 更早」分组。
- 空状态改成安静的一句话，垂直居中。
- 设置页文案缩短，别名空位显示「＋」而不是重复的「设置别名」。
- 面板标题改为「换个应用」，圆角 28、柔和阴影。

### 同步

- 小组件配色跟随新主题，「去输入」按钮改成雾绿。

## v1.2.1 — 选好应用直接搜（2026-11-05）

### 改动

- 首页：关键词已经填好时，应用名回车确认后**直接搜索**，不再把光标跳到关键词。
- 记录 / 想法的搜索面板：同样改成确认应用后直接搜。从记录再次点击时，关键词默认不变，只需要改应用名、回车，就完成搜索。
- 关键词为空时仍保持原行为：焦点交给关键词框，等输入。

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
