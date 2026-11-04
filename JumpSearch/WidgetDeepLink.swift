import Foundation
import WidgetKit

/// 解析小组件传进来的 mindsearch:// URL
///
/// - `mindsearch://search?app=小红书&q=关键词` → 有 q 直接搜，没 q 打开主 App 并聚焦关键词框
/// - `mindsearch://search` → 打开主 App，聚焦应用框
/// - `web=1` → 强制走网页兜底
struct WidgetDeepLink {
    let appName: String?
    let keyword: String?
    let forceWeb: Bool

    init?(url: URL) {
        guard url.scheme?.lowercased() == SharedData.urlScheme else { return nil }
        guard url.host?.lowercased() == "search" else { return nil }

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        // queryItems 的 value 已经是解码后的字符串，不要再 removingPercentEncoding
        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        let app = value("app")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = value("q")?.trimmingCharacters(in: .whitespacesAndNewlines)
        appName = (app?.isEmpty ?? true) ? nil : app
        keyword = (text?.isEmpty ?? true) ? nil : text
        forceWeb = value("web") == "1"
    }

    /// 是否要直接执行搜索（而不是只打开输入界面）
    var shouldSearch: Bool { keyword != nil && appName != nil }

    /// 刷新所有小组件（任何会改变列表的动作之后调用）
    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
