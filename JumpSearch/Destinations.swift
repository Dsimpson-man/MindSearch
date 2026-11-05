import Foundation

// MARK: - 分类
enum AppCategory: String, CaseIterable, Identifiable {
    case social = "社交媒体"
    case shopping = "购物"
    case life = "生活服务"
    case music = "音乐"
    case ai = "AI"

    var id: String { rawValue }
}

// MARK: - 一个可以去的应用
struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let category: AppCategory
    let scheme: String                 // 用于 Info.plist 白名单核对
    let appURL: (String) -> String     // 传入未编码的原文
    let webURL: (String) -> String     // 没装应用时的网页兜底
    var appTemplate: String = ""       // 可编辑的默认模板（含 {q}）
    var webTemplate: String = ""
    /// 打开前先把关键词写进剪贴板。
    /// 用于 URL scheme 带不进文字的 App（例如 DeepSeek 的 dpsk://）。
    var copyOnOpen: Bool = false
}

// 拼音 / 首字母，用于输入联想
private let searchKeys: [String: (pinyin: String, initials: String)] = [
    "小红书": ("xiaohongshu", "xhs"),
    "哔哩哔哩": ("bilibili", "blbl"),
    "豆瓣": ("douban", "db"),
    "微博": ("weibo", "wb"),
    "抖音": ("douyin", "dy"),
    "知乎": ("zhihu", "zh"),
    "YouTube": ("youtube", "yt"),
    "淘宝": ("taobao", "tb"),
    "天猫": ("tmall", "tm"),
    "京东": ("jingdong", "jd"),
    "拼多多": ("pinduoduo", "pdd"),
    "闲鱼": ("xianyu", "xy"),
    "美团": ("meituan", "mt"),
    "大众点评": ("dazhongdianping", "dzdp"),
    "饿了么": ("eleme", "elm"),
    "Spotify": ("spotify", "sp"),
    "DeepSeek": ("deepseek", "ds"),
    "Kimi": ("kimi", "kimi"),
    // 豆瓣已经占了 db，豆包用 dbk，否则输入 db 永远只认出豆瓣
    "豆包": ("doubao", "dbk"),
    "文小言": ("wenxiaoyan", "wxy"),
    "通义": ("tongyi", "ty"),
    "腾讯元宝": ("yuanbao", "yb"),
    "ChatGPT": ("chatgpt", "gpt")
]

extension Destination {
    /// 可用于识别开头应用名的写法
    func matchKeys(alias: String?) -> [String] {
        var keys = [name]
        if let key = searchKeys[name] {
            keys.append(key.pinyin)
            keys.append(key.initials)
        }
        if let alias, !alias.isEmpty {
            keys.append(alias)
        }
        return keys.filter { !$0.isEmpty }
    }
}

/// 关键词编码：排除会截断查询参数的字符
func encodeQuery(_ text: String) -> String {
    let allowed = CharacterSet.urlQueryAllowed
        .subtracting(CharacterSet(charactersIn: "&+=?#"))
    return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
}

private func destination(_ name: String,
                         _ category: AppCategory,
                         _ scheme: String,
                         app: String,
                         web: String,
                         copy: Bool = false) -> Destination {
    Destination(
        name: name,
        category: category,
        scheme: scheme,
        appURL: { app.replacingOccurrences(of: "{q}", with: encodeQuery($0)) },
        webURL: { web.replacingOccurrences(of: "{q}", with: encodeQuery($0)) },
        appTemplate: app,
        webTemplate: web,
        copyOnOpen: copy
    )
}

/// 京东的 params 是一段 JSON，必须整体 percent-encode
private func jdDestination() -> Destination {
    Destination(
        name: "京东",
        category: .shopping,
        scheme: "openapp.jdmobile",
        appURL: { text in
            let params: [String: String] = [
                "category": "jump",
                "des": "productList",
                "keyWord": text,
                "from": "search"
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: params),
                  let json = String(data: data, encoding: .utf8),
                  let encoded = json.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            else { return "openapp.jdmobile://virtual" }
            return "openapp.jdmobile://virtual?params=" + encoded
        },
        webURL: { "https://search.jd.com/Search?keyword=" + encodeQuery($0) },
        appTemplate: "openapp.jdmobile://virtual?params={\"category\":\"jump\",\"des\":\"productList\",\"keyWord\":\"{q}\",\"from\":\"search\"}",
        webTemplate: "https://search.jd.com/Search?keyword={q}"
    )
}

// MARK: - 全部应用
// 深链是第三方 App 的私有约定，没有官方保证；按分组顺序排列。
let destinations: [Destination] = [
    // 社交媒体
    destination("小红书", .social, "xhsdiscover",
                app: "xhsdiscover://search/result?keyword={q}",
                web: "https://www.xiaohongshu.com/search_result?keyword={q}"),
    destination("哔哩哔哩", .social, "bilibili",
                app: "bilibili://search?keyword={q}",
                web: "https://search.bilibili.com/all?keyword={q}"),
    destination("豆瓣", .social, "douban",
                app: "douban:///search?q={q}",
                web: "https://www.douban.com/search?q={q}"),
    destination("微博", .social, "sinaweibo",
                app: "sinaweibo://searchall?q={q}",
                web: "https://s.weibo.com/weibo?q={q}"),
    destination("抖音", .social, "snssdk1128",
                app: "snssdk1128://search?keyword={q}",
                web: "https://www.douyin.com/search/{q}"),
    destination("知乎", .social, "zhihu",
                app: "zhihu://search?q={q}",
                web: "https://www.zhihu.com/search?type=content&q={q}"),
    destination("YouTube", .social, "youtube",
                app: "youtube://results?search_query={q}",
                web: "https://www.youtube.com/results?search_query={q}"),

    // 购物
    destination("淘宝", .shopping, "taobao",
                app: "taobao://s.taobao.com/search?q={q}",
                web: "https://s.taobao.com/search?q={q}"),
    destination("天猫", .shopping, "tmall",
                app: "tmall://page.tm/search?q={q}",
                web: "https://list.tmall.com/search_product.htm?q={q}"),
    jdDestination(),
    destination("拼多多", .shopping, "pinduoduo",
                app: "pinduoduo://yangkeduo.com/search_result.html?search_key={q}",
                web: "https://mobile.yangkeduo.com/search_result.html?search_key={q}"),
    // 闲鱼搜索：fleamarket://x_search_items?keyword={q}（2026-11 拿到，可直接带关键词）。
    destination("闲鱼", .shopping, "fleamarket",
                app: "fleamarket://x_search_items?keyword={q}",
                web: "https://www.goofish.com/search?q={q}"),

    // 生活服务
    destination("美团", .life, "imeituan",
                app: "imeituan://www.meituan.com/search?q={q}",
                web: "https://www.meituan.com/s/{q}/"),
    destination("大众点评", .life, "dianping",
                app: "dianping://searchshoplist?keyword={q}",
                web: "https://www.dianping.com/search/keyword/0_0_{q}"),
    destination("饿了么", .life, "eleme",
                app: "eleme://search?keyword={q}",
                web: "https://www.ele.me/search?keyword={q}"),

    // 音乐
    destination("Spotify", .music, "spotify",
                app: "spotify:search:{q}",
                web: "https://open.spotify.com/search/{q}"),

    // AI 服务商
    // DeepSeek 的 dpsk:// 只能打开 App、带不进文字，所以改成「先复制关键词，再打开 App」。
    // 其他 AI 大多是网页 ?q=，参数不一定被接住，也加一层剪贴板兜底。
    // 豆包确认能通过 doubao://chat?text= 直接带文本，保持直连。
    destination("DeepSeek", .ai, "dpsk",
                app: "dpsk://",
                web: "https://chat.deepseek.com/?q={q}&autosend=1&search=1",
                copy: true),
    destination("Kimi", .ai, "kimi",
                app: "https://www.kimi.com/?q={q}",
                web: "https://www.kimi.com/?q={q}",
                copy: true),
    destination("豆包", .ai, "doubao",
                app: "doubao://chat?text={q}",
                web: "https://www.doubao.com/?q={q}"),
    destination("文小言", .ai, "yiyan",
                app: "https://yiyan.baidu.com/?q={q}",
                web: "https://yiyan.baidu.com/?q={q}",
                copy: true),
    destination("通义", .ai, "tongyi",
                app: "https://www.qianwen.com/?q={q}",
                web: "https://www.qianwen.com/?q={q}",
                copy: true),
    destination("腾讯元宝", .ai, "yuanbao",
                app: "https://yuanbao.tencent.com/chat?q={q}",
                web: "https://yuanbao.tencent.com/chat?q={q}",
                copy: true),
    destination("ChatGPT", .ai, "chatgpt",
                app: "https://chatgpt.com/?q={q}",
                web: "https://chatgpt.com/?q={q}",
                copy: true)
]
