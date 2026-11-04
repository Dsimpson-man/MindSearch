import SwiftUI
import UIKit

/// 和主 App 一致的暖雾 / 暖黑配色，单独定义一份，避免把整个 ContentView 编进 Extension。
enum WidgetPalette {
    static let paper = dynamic(light: (0.957, 0.945, 0.918),
                               dark:  (0.110, 0.102, 0.090))
    static let card = dynamic(light: (0.929, 0.914, 0.874),
                              dark:  (0.149, 0.137, 0.122))
    static let ink = dynamic(light: (0.227, 0.212, 0.188),
                             dark:  (0.929, 0.910, 0.874))
    static let accent = dynamic(light: (0.420, 0.478, 0.416),
                                dark:  (0.659, 0.710, 0.627))
    static let faded = ink.opacity(0.42)

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat),
                                dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }

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
