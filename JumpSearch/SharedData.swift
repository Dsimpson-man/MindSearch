import Foundation

// MARK: - App Group 共享数据（主 App 写，Widget 只读）
//
// Widget Extension 是独立进程，读不到 UserDefaults.standard，
// 所以两边都通过 App Group 的 suite 交换数据。
// 这个文件只依赖 Foundation，可以同时编译进主 App 和 Widget Extension。

enum SharedData {
    static let groupID = "group.com.humengdie.JumpSearch.shared"
    static let urlScheme = "mindsearch"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    private enum Key {
        static let recentAppNames = "widget.recentAppNames"
        static let defaultAppName = "widget.defaultAppName"
        static let useDefaultApp = "widget.useDefaultApp"
        static let aliases = "widget.aliases"
        static let urlOverrides = "widget.urlOverrides"
        static let lastKeyword = "widget.lastKeyword"
        static let lastAppName = "widget.lastAppName"
        static let bootstrapped = "widget.bootstrapped"
    }

    static let maxRecent = 4

    // MARK: - 写入（只在主 App 调用）

    /// - Parameters:
    ///   - recentApps: 按最近使用排序的应用名（已去重，最多 4 个）
    ///   - lastKeyword / lastApp: 最近一次搜索，用于锁屏小组件显示
    static func publish(recentApps: [String],
                        lastKeyword: String?,
                        lastApp: String?,
                        aliases: [String: String],
                        defaultAppName: String,
                        useDefaultApp: Bool,
                        urlOverrides: [String: String]) {
        let d = defaults
        d.set(Array(recentApps.prefix(maxRecent)), forKey: Key.recentAppNames)
        d.set(defaultAppName, forKey: Key.defaultAppName)
        d.set(useDefaultApp, forKey: Key.useDefaultApp)
        d.set(encode(aliases), forKey: Key.aliases)
        d.set(encode(urlOverrides), forKey: Key.urlOverrides)
        d.set(lastKeyword ?? "", forKey: Key.lastKeyword)
        d.set(lastApp ?? "", forKey: Key.lastAppName)
        d.set(true, forKey: Key.bootstrapped)
    }

    /// 老用户升级后第一次启动，把已有数据补进 App Group，避免小组件空白
    static func bootstrapIfNeeded(recentApps: [String],
                                  lastKeyword: String?,
                                  lastApp: String?,
                                  aliases: [String: String],
                                  defaultAppName: String,
                                  useDefaultApp: Bool,
                                  urlOverrides: [String: String]) {
        guard !defaults.bool(forKey: Key.bootstrapped) else { return }
        publish(recentApps: recentApps, lastKeyword: lastKeyword, lastApp: lastApp,
                aliases: aliases, defaultAppName: defaultAppName,
                useDefaultApp: useDefaultApp, urlOverrides: urlOverrides)
    }

    /// 从历史记录里提出最近用过的 App 名（主 App 侧调用）
    static func recentApps(from historyTexts: [(text: String, app: String)]) -> [String] {
        var result: [String] = []
        for item in historyTexts {
            let name = item.app
                .replacingOccurrences(of: " · 网页", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard destinations.contains(where: { $0.name == name }) else { continue }
            if !result.contains(name) { result.append(name) }
            if result.count >= maxRecent { break }
        }
        return result
    }

    // MARK: - 读取（Widget 侧）

    struct Snapshot {
        var apps: [WidgetApp] = []
        var lastKeyword: String = ""
        var lastAppName: String = ""
        var isEmpty: Bool { apps.isEmpty }
    }

    static func snapshot() -> Snapshot {
        let d = defaults
        var snap = Snapshot()

        let aliases = decode(d.data(forKey: Key.aliases))
        let overrides = decode(d.data(forKey: Key.urlOverrides))

        var names: [String] = d.stringArray(forKey: Key.recentAppNames) ?? []
        let defaultName = d.string(forKey: Key.defaultAppName) ?? ""
        if d.bool(forKey: Key.useDefaultApp),
           destinations.contains(where: { $0.name == defaultName }),
           !names.contains(defaultName) {
            names.insert(defaultName, at: 0)
        }
        // 从没搜过时也给一排可点的常用应用，不让小组件空白
        for fallback in ["小红书", "哔哩哔哩", "抖音", "知乎"] {
            if names.count >= maxRecent { break }
            if !names.contains(fallback) { names.append(fallback) }
        }

        snap.apps = names.prefix(maxRecent).compactMap { name in
            guard let dest = destinations.first(where: { $0.name == name }) else { return nil }
            return WidgetApp(
                name: dest.name,
                displayName: aliases[name].flatMap { $0.isEmpty ? nil : $0 } ?? dest.name,
                template: overrides[name] ?? dest.appTemplate,
                category: dest.category.rawValue
            )
        }
        snap.lastKeyword = d.string(forKey: Key.lastKeyword) ?? ""
        snap.lastAppName = d.string(forKey: Key.lastAppName) ?? ""
        return snap
    }

    // MARK: - Deep link
    //
    // Widget 里没有 UIApplication.shared，不能直接打开第三方 App。
    // 点击统一唤起 MindSearch 本体，由本体完成跳转（WidgetKit 的硬限制）。

    /// mindsearch://search?app=小红书&q=关键词
    static func searchURL(app: String, keyword: String, web: Bool = false) -> URL? {
        var comps = URLComponents()
        comps.scheme = urlScheme
        comps.host = "search"
        var items = [URLQueryItem(name: "app", value: app)]
        if !keyword.isEmpty { items.append(URLQueryItem(name: "q", value: keyword)) }
        if web { items.append(URLQueryItem(name: "web", value: "1")) }
        comps.queryItems = items
        return comps.url
    }

    /// 打开主 App 并准备输入关键词（q 为空时聚焦关键词框）
    static func composeURL(app: String?) -> URL? {
        var comps = URLComponents()
        comps.scheme = urlScheme
        comps.host = "search"
        if let app, !app.isEmpty {
            comps.queryItems = [URLQueryItem(name: "app", value: app)]
        }
        return comps.url
    }

    // MARK: - helpers

    private static func encode(_ dict: [String: String]) -> Data? {
        try? JSONEncoder().encode(dict)
    }

    private static func decode(_ data: Data?) -> [String: String] {
        guard let data,
              let value = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return value
    }
}

// MARK: - Widget 用的轻量模型

struct WidgetApp: Identifiable, Hashable {
    let name: String
    let displayName: String
    let template: String
    let category: String

    var id: String { name }

    /// 小尺寸里放不下的名字缩一下
    var shortName: String {
        switch name {
        case "哔哩哔哩": return "B 站"
        case "大众点评": return "点评"
        case "腾讯元宝": return "元宝"
        case "DeepSeek": return "DS"
        case "ChatGPT": return "GPT"
        case "YouTube": return "YT"
        case "Spotify": return "Spotify"
        default: return String(displayName.prefix(3))
        }
    }

    var symbol: String {
        switch name {
        case "小红书": return "book.closed"
        case "哔哩哔哩": return "play.rectangle"
        case "抖音": return "music.note"
        case "微博": return "bubble.left"
        case "知乎": return "questionmark.circle"
        case "豆瓣": return "film"
        case "YouTube": return "play.circle"
        case "淘宝", "天猫", "京东", "拼多多", "闲鱼": return "bag"
        case "美团", "大众点评", "饿了么": return "fork.knife"
        case "Spotify": return "music.note.list"
        case "DeepSeek", "Kimi", "豆包", "文小言", "通义", "腾讯元宝", "ChatGPT": return "sparkles"
        default: return "magnifyingglass"
        }
    }
}
