# CHANGELOG

## v3.0.0 — 回车恒搜索 + 想法卡片（2026-11-06）

按 `docs/CHANGE-SPEC-v3.md` 落地，但**保留底部两个入口**（不删 tab）——想法是主功能，删掉会让它失去发现性。

### 新增

- **回车恒等于搜索**，任何长度都一样；超过阈值（默认 20 字）时右下角出现雾绿「存为想法」次按钮，长按主按钮可强制存。
- **关键词框自增高**：`UITextView` 包一层 `UIViewRepresentable`，1 行 42pt、2 行自动撑开、3 行 108pt 封顶后框内滚动；换行键只提交，组字期间吞掉。首页和「换个应用」面板都用它。
- **想法改成卡片**：点一下就地编辑（内嵌多行输入框），回车或「完成」收起；卡片右下角有显式删除入口。
- **最近三个应用**：应用槽空着、还没打字时，句子下面浮一行「最近 小红书 豆瓣 闲鱼」，点一下填入并跳到关键词。
- **左滑删除**：自建 `DragGesture`，阈值 72pt，跟手位移、不到阈值回弹，保留原来的无边框 + 0.5pt 细线排版。
- **触觉**：搜索 `impact(.light)`、存想法 `notification(.success)`、切换页面 `selection`。
- **存想法飞点**：绿点从主按钮飞向底部「想法」入口，320ms，中途抬 22pt。
- `Theme.danger` / `Theme.onDanger`：删除区域的砖红色，深色模式单独取值。

### 修复

- **搜索会覆盖默认 APP**：`search()` 里无条件写 `store.defaultAppName = d.name`，用豆瓣搜一次就把设置里的默认应用永久改成豆瓣。已删除这行。
- **关掉「启用默认 APP」不生效**：`defaultDestination` 只看 `defaultAppName` 是否为空，不看开关。现在必须开关为真才回落到默认应用。
- **引导页写死 20 字**：改为读 `store.ideaThreshold`，设置里改过之后文案跟着变；文案同步改成新的回车语义。
- **`db` 别名冲突**：豆瓣和豆包都是 `db`，豆包永远拿不到。豆包改用 `dbk`。
- **清空记录没有二次确认**：加 `confirmationDialog`。
- **`swipeActions` 挂在 `LazyVStack` 上不生效**：换成自建手势，删除真正可用。
- **长按关键词框抢走文本选择**：关键词框换成多行 `UITextView` 后，长按要留给选词/光标，所以移除了关键词框上的「按住说话」手势；麦克风按钮仍在，点一下就能说。

### 改动

- 顶部去掉 wordmark，只留右侧设置入口；非搜索页左侧保留「‹ 搜索」。
- 主按钮不再 `repeatForever` 呼吸，改成静止的环，有关键词时内圈收紧。
- 动效收敛到四档：按压 90ms、状态 180ms、页面 220ms、面板 340ms；页面之间交叉淡入，不做横向位移；`accessibilityReduceMotion` 为真时全部关闭。
- 删除死代码：`LiquidIndicator`、`pulse`、`tabNamespace`。

### 文档

- README 的界面、已知问题、scheme 白名单说明同步到 v3。
- `docs/CHANGE-SPEC-v3.md` 的第 1.2 节（删底部 tab）未执行，其余按文档落地。

## 未发布 — v3 结构方案（2026-11-05）

只有文档，没有代码改动。

### 新增

- `docs/CHANGE-SPEC-v3.md`：结构层的改动方案。删掉呼吸圆、底部 tab、顶部 wordmark；想法改卡片并支持就地编辑；回车恒等于搜索，「存为想法」降级为次按钮；动效收敛到四档并加触觉。

### 文档

- `docs/CHANGE-SPEC-v2.2.md` 顶部加上与 v3 的关系说明，标明哪几条仍然有效、哪条被取代。
- README 改为指向 v3，v2.2 保留为「保留现有结构」的备选。

## 未发布 — v2.2 需求定稿（2026-11-05）

只有文档，没有代码改动。

### 新增

- `docs/CHANGE-SPEC-v2.2.md`：下一版的改动需求，含回车语义状态表、关键词框自增高、动效参数表、左滑删除方案、验收清单和建议提交顺序。

### 文档

- README 的「已知问题」加上指向该需求的入口。

## v2.1.3 — URL Scheme 手册（2026-11-05）

### 新增

- `docs/URL-SCHEMES.md`：URL Scheme 的获取方法、常见坑、与本项目深链的对应关系，以及新增一个 App 的标准流程。
- README 的深链章节加上指向该手册的入口。

## v2.1.2 — 闲鱼直连搜索 + 评审归档（2026-11-05）

### 新增

- `docs/UI-REVIEW.md`：完整的产品与设计评审，含优先级矩阵、落地方案、分档排期和真机验收清单。

### 改动

- 闲鱼改为直连 `fleamarket://x_search_items?keyword={q}`，关键词可直接带进搜索页，不再走剪贴板模式。`copyOnOpen` 机制保留给其他 App。

### 文档

- README 修正「左滑删除」的表述（该交互当前不生效，需长按删除），并补两条已知问题。

## v2.1.1 — 闲鱼改为剪贴板（2026-11-05）

- 闲鱼没有公开的搜索 scheme（`search` / `searchResult` 实测都进不了搜索页），改成 `fleamarket://` 只打开 App + 复制关键词，进去点搜索框粘贴。
- 网页兜底保持 `https://www.goofish.com/search?q={q}`。

## v2.1.0 — 首次引导 + 深色模式（2026-11-05）

### 新增

- **首次引导**：三页，讲清楚「一句话搜索」「XH = 小红书」「长文本存想法」。用 `@AppStorage("hasSeenOnboarding")` 记录，只看一次。
- **深色模式**：暖黑 `#1C1A17` / 卡片 `#262320` / 暖白字 `#EDE8DF` / 亮雾绿 `#A8B5A0`。跟随系统切换，主 App 和小组件同步。
- Theme 改成动态色（`UIColor(dynamicProvider:)`），UIKit 输入框单独用动态 `UIColor`，避免深色下光标/占位符不跟随。

### 修复

- 闲鱼搜索深链改成 `fleamarket://searchResult?keyword={q}`，并加剪贴板兜底（打开 App 后可直接粘贴）。

### 移除

- 不再强制浅色模式（`UIUserInterfaceStyle = Light` 从两个 Info.plist 移除）。

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
