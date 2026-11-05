# URL Scheme 获取与维护手册

> 本文是 MindSearch 的内部工作笔记，用于给 `Destinations.swift` 补充、核对和修复第三方 App 的搜索深链。
> 内容为原创整理，**不是**对参考文章的转载。原文版权归原作者所有，原文页脚注明「禁止转载」，请直接访问原文阅读完整教程：
> - 原文：<https://www.ydzms.com/archives/176/>（《URL Scheme教程｜如何获取url scheme？》，云端筑梦室，最后修改 2025-06-15）
> - 同站参数大全：<https://www.ydzms.com/archives/58/>

---

## 1. 一句话理解

URL Scheme 是 App 之间的「电话号码」：`scheme://host/path?query`。

- `fleamarket://` —— 拨号，唤起闲鱼。
- `://` 后面的部分 —— 具体分机号，决定打开哪个页面、带什么参数。

以原文的闲鱼「擦亮宝贝」为例，一条完整 scheme 可以拆成四段：

```
fleamarket://2.taobao.com/onepiece?source=auto&action=ali.open.nav&module=h5&bootImage=0&h5Url=<目标网页>&ut_sk=&spm=...&adv=no&isFishAutoLogin=false
│            │                        │                                                    │
①唤起协议    ②打开 URL 的固定参数        ③真正要去的 H5 页面                                    ④客户端判断参数
```

对我们有用的通常是 ①+③：用 App 的「打开网页」通道，把带关键词的 H5 搜索页塞进去。

---

## 2. 八种获取方式（按可靠性排序）

| # | 方式 | 可靠性 | 说明 |
| --- | --- | --- | --- |
| 1 | **IPA 里的 `Info.plist`** | 最高 | 解压 ipa → `Payload/App.app/Info.plist` → `CFBundleURLTypes` → `CFBundleURLSchemes`。这是 App 自己声明的权威列表。手机上可用 Filza 走 `/var/containers/Bundle/Application/.../App.app/Info.plist`。 |
| 2 | **官方文档** | 高 | 有开放平台的 App（如微信小程序）会写明生成规则和限制。 |
| 3 | **第三方 scheme 大全** | 中 | 现成但可能过期，必须真机复验。原文同站的参数大全即属此类。 |
| 4 | **抓包** | 中 | 手机端 Stream / HTTP Catcher / Quantumult X / Spider Proxy；电脑端 Charles / Fiddler / Burp。 |
| 5 | **浏览器开发者工具 / 拦截** | 中 | 桌面 QQ 浏览器拦截跳转；iOS 用 Alook 拦截。适合从「分享出来的链接」反推。 |
| 6 | **搜索引擎** | 低 | 最快，但版本相关性最差。 |
| 7 | **官方营销短信里的短链** | 低 | 能拿到 H5 页面，仍需自己配 scheme。 |
| 8 | **解包应用** | 低 | 门槛高，收益不稳定。 |

### 抓包的实操顺序

1. 先拿到该 App「打开网页」的 scheme（形如 `xxx://webview?url=`）。
2. 开抓包 → 进 App → 点到目标页面 → 回抓包工具找响应。
3. 在响应里搜 `h5`、`url`、`today`、`task`、`sign` 这类关键词。
4. 取出 H5 地址，和 scheme 拼起来。

### 三个容易踩的坑

- **`\/` 转义**：抓到的 JSON 里 URL 常写成 `https:\/\/a.com\/b`，要还原成 `https://a.com/b`。
- **Base64**：`redirect_data` 之类的字段可能是 Base64，解一次才能看到真实 URL。
- **要不要编码**：有的 App 要求 URL 参数整体 percent-encode，有的不接受编码（原文里高德就不用编码）。两种都试。

---

## 3. 原文里可直接用的现成 scheme（非搜索类）

以下为原文列举的示例，属于「打开某个功能页」而非「搜索」，仅作参考，未在本项目中启用：

| 目标 | Scheme |
| --- | --- |
| QQ | `mqq://` |
| 微信 | `weixin://`（如 `weixin://scanqrcode`） |
| 淘宝 | `taobao://` |
| 支付宝 | `alipays://platformapi/startapp?appId=...&url=...` |
| 电池电量（系统设置） | `prefs:root=BATTERY_USAGE` |
| 蜂窝数据 | `prefs:root=MOBILE_DATA_SETTINGS_ID` |
| Wi-Fi 设置 | `prefs:root=WIFI` |
| 蓝牙设置 | `prefs:root=Bluetooth` |
| 关于本机 | `prefs:root=General&path=About` |

> 系统设置的 `prefs:` 前缀在较新 iOS 上已大范围失效，仅作历史参考。

---

## 4. 与本项目的关系

### 4.1 当前搜索深链

完整清单见 README 的「内置应用与深链」表。所有条目都遵循同一个模板：

```
<scheme>://<path>?<参数名>={q}
```

`{q}` 由 `Destinations.swift` 里的 `encodeQuery()` 替换（排除了 `&+=?#`，避免截断查询参数）。

### 4.2 新增一个 App 的标准流程

1. **拿 scheme**：优先解 IPA 的 `Info.plist`。
2. **找搜索页**：抓包拿到该 App 搜索结果的 H5 地址，确认关键词参数名。
3. **确认通道**：该 scheme 是否支持「打开任意 URL」（`?url=` / `?h5Url=`）；不支持就只能打开 App 本身。
4. **拼模板**：写成 `scheme://...?参数={q}`，必要时整体 percent-encode。
5. **加白名单**：`JumpSearch/Info.plist` 的 `LSApplicationQueriesSchemes` 必须包含该 scheme，否则 `canOpenURL` 永远返回 false，会静默走网页兜底。
6. **加条目**：`Destinations.swift` 的 `destinations` 数组，补 `searchKeys` 里的拼音/首字母。
7. **真机验证**：模拟器没有这些 App，必须真机。

### 4.3 需要复验的条目

- 所有标注「社区流传」的深链：抖音、淘宝、天猫、闲鱼、饿了么、Spotify。
- 闲鱼新 scheme `fleamarket://x_search_items?keyword={q}`（2026-11 拿到，尚未在真机确认）。

---

## 5. 两个必须知道的限制

### 5.1 scheme 冲突

两个 App 注册同一个 scheme 时，iOS **优先打开先安装的那个**。原文举的例子：中国移动云盘与已下架的和彩云都用 `mcloud://`，先装谁就跳谁，卸载旧 App 才能恢复。

对本项目的含义：`canOpenURL` 为 true 不代表打开的就是你期望的那个 App。遇到「跳错 App」优先怀疑这个原因，而不是 URL 写错。

### 5.2 微信小程序的 scheme

需要企业资质（认证费 300 元），生成的 scheme **只有生成者可访问**，且**有效期 30 天**。所以本项目不可能通过 scheme 稳定直达微信小程序页面，只能打开微信本体。

---

## 6. 参考与延伸

原文列出的优质来源（仅索引，未逐条核验）：

- URL Scheme 大全（同站）：<https://www.ydzms.com/archives/58/>
- 含参数的 URL Scheme 收集：<https://gist.github.com/JamesHopbourn/046bc341e7debfd0c86e3b388d983c53>
- 抖音 / TikTok / 快手 scheme 收集：<https://github.com/Oct1a/TikTok-Scheme>
- 常用 URL Scheme 收集：<https://gist.github.com/zhuziyi1989/3f96a73c45a87778b560e44cb551ebd2>
- 知乎讨论：<https://www.zhihu.com/question/19907735>
- 少数派《URL Schemes 使用详解》：<https://sspai.com/post/31500>
- 少数派《URL Scheme 查询指南》：<https://sspai.com/post/66334>
- 少数派《入门 iOS 自动化：读懂 URL Schemes》：<https://sspai.com/post/44591>
