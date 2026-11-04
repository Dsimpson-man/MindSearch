import SwiftUI

/// 和主 App 一致的纸张 / 墨色，单独定义一份，避免把整个 ContentView 编进 Extension。
enum WidgetPalette {
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.85)
    static let card = Color(red: 0.91, green: 0.87, blue: 0.78)
    static let ink = Color(red: 0.17, green: 0.13, blue: 0.10)
    static let faded = Color(red: 0.17, green: 0.13, blue: 0.10).opacity(0.55)

    static func mono(_ size: CGFloat, bold: Bool = false) -> Font {
        .system(size: size, weight: bold ? .bold : .regular, design: .monospaced)
    }

    static func serif(_ size: CGFloat) -> Font {
        .custom("Songti SC", size: size)
    }
}

/// iOS 17 起主屏小组件必须用 containerBackground；锁屏样式由系统自己上色，不叠加纸张。
struct WidgetContainerBackground: ViewModifier {
    @Environment(\.widgetFamily) private var family

    @ViewBuilder
    func body(content: Content) -> some View {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            if #available(iOS 17.0, *) {
                content.containerBackground(for: .widget) { WidgetPalette.paper }
            } else {
                content.background(WidgetPalette.paper)
            }
        default:
            content
        }
    }
}
