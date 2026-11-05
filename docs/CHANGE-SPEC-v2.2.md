# v2.2 改动需求

> **结构方案已更新。** 后来出的 [`CHANGE-SPEC-v3.md`](CHANGE-SPEC-v3.md) 把「回车可见化」换成了「回车恒等于搜索」，并删掉了底部 tab。
> 本文的 §2（输入框自增高）、§3（动效）、§4（左滑删除）、§5（小问题）在 v3 里继续有效；§1 只在「保留现有结构」时使用。

这一版只解决三件事：**回车到底干什么、长文本能不能看见、动效快不快**。

配色、URL Scheme、数据结构都不动。下面每一条都能单独提 PR，按 P0 → P1 的顺序做。

---

## 1. 回车语义（P0）

### 现状

- `JumpSearch/ContentView.swift:869` —— `submit()` 里用 `text.count > store.ideaThreshold` 决定存想法还是搜索，**用户按下去之前不知道会怎样**。
- `JumpSearch/ContentView.swift:470` —— 提示文案写死「存为想法」，只在超阈值时出现，没有反向的「其实这次是搜索」。
- `JumpSearch/UIKitTextField.swift:25` —— `returnKeyType` 只在 `makeUIView` 设了一次，之后不会跟着状态变。

### 目标行为

| 条件 | 回车结果 | 主按钮图标 | 键盘回车键 | 胶囊 |
| --- | --- | --- | --- | --- |
| 关键词 ≤ 阈值 | 搜索 | `arrow.right` | `.search` | 不显示 |
| 关键词 > 阈值 | 存为想法 | `bookmark` | `.done` | `21 字 · 回车存为想法` |
| 手动切成搜索 | 搜索 | `arrow.right` | `.search` | `21 字 · 回车直接搜索`（雾绿） |
| 长按主按钮 | 存为想法 | 不变 | 不变 | 不变 |

### 规则

1. **覆盖是一次性的**：手动切过之后，这次执行完就清空，下次回到按字数判定。
2. 文本掉回阈值以内，覆盖自动失效。
3. **输入法组字期间不重算**（`isComposing == true`），也不要改 `returnKeyType`，否则候选词会被吞。
4. 面板（从记录 / 想法点进来那个）里的关键词**永远搜索**，不参与判定 —— 那里没有「存想法」这个选项。
5. 胶囊本身可点，点一下就是切模式，不需要长按。

### 实现要点

```swift
enum SubmitIntent { case search, idea }

// 判定
func intent(for text: String) -> SubmitIntent {
    if let o = overrideIntent { return o }
    return text.count > store.ideaThreshold ? .idea : .search
}
```

- `UIKitTextField.updateUIView` 补一行，让回车键跟着状态走：

```swift
if field.returnKeyType != returnKey {
    field.returnKeyType = returnKey
    if field.isFirstResponder { field.reloadInputViews() }  // iOS 16+ 键盘已弹出时必须刷新
}
```

- `isComposing` 已经在这个 representable 里了（`UIKitTextField.swift:99`），直接复用，不用新加。

### 验收

- [ ] 打 19 个字回车 → 搜索
- [ ] 打 21 个字回车 → 存为想法，按钮图标是书签
- [ ] 点胶囊切成「直接搜索」→ 21 个字回车 → 搜索，且下一次重新按字数判定
- [ ] 拼音打到一半按回车，不会把半截拼音存成想法
- [ ] 从记录点进来的面板里，回车永远是搜索

---

## 2. 关键词输入框自增高（P0）

### 现状

`keywordField` 是单行 `UITextField`。29 个字的想法只能看见尾巴 —— 网页原型里复现过，输入框显示的是「、营地灯，预算两千以内」，前面全被推到看不见的地方。

**「存想法」这个功能，输入的时候是看不见自己写了什么的。** 这条不修，第 1 条做了也没意义。

### 目标行为

| 行数 | 高度 | 说明 |
| --- | --- | --- |
| 1 行 | 42pt | 默认，和现在一致 |
| 2 行 | ~72pt | 自动撑开 |
| 3 行 | 108pt | 封顶，再长就在框内滚动 |

高度变化用 180ms 动画，不要突然跳。

### 实现要点

- `UITextField` 不支持多行，要换成 `UITextView` 包一层 `UIViewRepresentable`。
- 必须拦换行，否则回车变成换行而不是提交：

```swift
func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange,
              replacementText text: String) -> Bool {
    if text == "\n" { parent.onSubmit(); return false }
    return true
}
```

- `UITextView` 没有 placeholder，要自己叠一个 `UILabel`，跟着 `text.isEmpty` 显隐。
- 三处默认值要清零，否则和左边的「搜索」标签对不齐：`textContainerInset = .zero`、`textContainer.lineFragmentPadding = 0`、`isScrollEnabled = false`。
- 高度约束：`>= 42`、`<= 108`，中间由内容撑开；超过 108 再开滚动。
- 组字判断换成 `textView.markedTextRange != nil`。
- 深色模式：光标 `tintColor`、文字色、placeholder 色都沿用 `Theme` 里现有的动态 `UIColor`。

### 验收

- [ ] 打一行不撑高，第二行开始撑开，三行封顶
- [ ] 三行以内回车提交，不会插入换行符
- [ ] 删回一行，高度收回去
- [ ] 深色模式下光标和 placeholder 颜色正确

---

## 3. 动效（P1）

### 现状

- `PressableStyle` 0.28s
- `BreathingSubmitButton` 3.4s `repeatForever`
- 全局 0.45–0.9s `easeInOut`

效率工具不该有 0.9s 的动画 —— 按下去到看见结果，中间那 0.9 秒全是等待。

### 参数表

| 场景 | 时长 | 曲线 |
| --- | --- | --- |
| 按压反馈 | 90ms | `timingCurve(0.16, 1, 0.3, 1)` |
| 下划线展开 / 图标切换 | 180ms | 同上 |
| 状态切换、页面进出 | 220ms | 同上 |
| 面板升起 | 340ms | `timingCurve(0.2, 1.08, 0.3, 1)`（约 1% 过冲） |
| 飞点（存想法） | 320ms | `timingCurve(0.16, 1, 0.3, 1)`，中途抬 22pt |
| 列表逐行入场 | 每行 +24ms | 最多 6 行，之后同批 |

### 三条硬规则

1. **上限 360ms**。超过就砍，不要用「更柔和」当理由。
2. **只动 `transform` / `opacity`**，不要动 frame 和颜色以外的属性。
3. **可打断**。动画没跑完时用户再点，要立刻响应，不要等它播完。

### 呼吸圆

现在是 `repeatForever`，等于永久占着一帧。改成**入场呼吸 2 次就停**，之后交给状态（有关键词时收紧成实心圆）。

### 降低动态效果

`@Environment(\.accessibilityReduceMotion)` 为真时，所有时长塌到 0，呼吸圆直接静止。

### 验收

- [ ] 从按下搜索到出现 toast，体感在 0.4s 以内
- [ ] 呼吸圆 2 次之后不再动
- [ ] 打开「减弱动态效果」后没有位移动画

---

## 4. 列表左滑删除（P0）

### 现状

`JumpSearch/ContentView.swift:653` 和 `:681` 是 `ScrollView` + `LazyVStack`，`:665` 和 `:718` 的 `.swipeActions` **完全不生效** —— `swipeActions` 只对 `List` 里的行有效。README 之前写的「左滑删除」是错的，已经在 v2.1.2 更正。

### 两条路

**A. 换成 `List`** —— 改动最小，但 `List` 自带背景、分隔线、行内边距，要把这套「无边框 + 0.5pt 细线」的样式一点点压回去，容易反复。

**B. 自建 `DragGesture`** —— 保持现有排版，自己处理位移、回弹、删除。

建议 **B**：这个页面的留白和细线是设计的一部分，换成 `List` 大概率要打一圈补丁才能还原。

### 行为

- 左滑阈值 72pt，超过就删，不到就回弹（180ms）。
- 松手前跟手位移，`offset(x: min(0, drag))`。
- 删除后焦点落到下一条；列表空了落到对应的 tab。
- 桌面 / 无障碍场景保留一个显式删除入口（不要只留手势）。

### 验收

- [ ] 左滑超过 72pt 删除，不到就回弹
- [ ] 删除后剩下的行不会跳位
- [ ] 用 VoiceOver 也能删

---

## 5. 顺手要修的三个小问题（P1）

1. **`UIKitTextField.swift:39` 的 `cancelsTouchesInView = true`** —— 长按手势挂在应用名输入框上，会吃掉系统的长按选词 / 放大镜。改成 `false`，或者只给关键词框装这个手势。
2. **`db` 冲突** —— `Destinations.swift` 的 `searchKeys` 里豆瓣和豆包都映射到 `db`，输入 `db` 补全永远是豆瓣，豆包拿不到。给豆包加一个 `dbk`，或者在补全处显示候选数量（网页原型里显示成 `db 豆瓣 +1`）。
3. **清空记录没有二次确认** —— 一次误触就没了。加一个 `confirmationDialog`。

---

## 6. 这一版不做

- 不改配色和字体
- 不改 URL Scheme / 深链
- 不做 iCloud 同步
- 不改小组件

---

## 7. 网页原型

本地有一份可点的 HTML 原型（`index.html`，在 Open Design 项目根目录，**没有进这个仓库**），用来对照手感和参数。所有数值以本文为准；原型是参考，不是实现。

如果希望把原型也放进仓库方便对照，说一声，我提到 `docs/prototype/` 下。

---

## 8. 建议的提交顺序

1. `feat: 关键词输入框自增高到三行`（第 2 条）—— 单独一个 PR，它决定了后面文案怎么写
2. `feat: 回车语义可见化`（第 1 条）
3. `fix: 列表左滑删除`（第 4 条）
4. `style: 动效参数统一`（第 3 条）
5. `fix: 三个小问题`（第 5 条）

前两条一起做也行，但**不要**先做第 1 条再做第 2 条 —— 单行框里做可见化，等于给一个看不见的东西加标签。
