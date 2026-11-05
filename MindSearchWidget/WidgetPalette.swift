import SwiftUI
import UIKit

/// 和主 App 一致的雾面莫兰迪配色，单独定义一份，避免把整个 ContentView 编进 Extension。
enum WidgetPalette {
    static let paper = dynamic(light: (0.906, 0.898, 0.886),
                               dark:  (0.086, 0.082, 0.098))
    static let skyTop = dynamic(light: (0.929, 0.918, 0.902),
                                dark:  (0.106, 0.102, 0.121))
    static let skyBottom = dynamic(light: (0.867, 0.863, 0.863),
                                   dark:  (0.067, 0.063, 0.078))
    static let card = dynamic(light: (0.945, 0.937, 0.925),
                              dark:  (0.141, 0.137, 0.157))
    static let ink = dynamic(light: (0.227, 0.216, 0.204),
                             dark:  (0.902, 0.886, 0.867))
    static let accent = dynamic(light: (0.463, 0.514, 0.463),
                                dark:  (0.678, 0.725, 0.667))
    static let faded = ink.opacity(0.60)

    /// 小组件的主屏底色：和主 App 同一层的渐变
    static var sky: LinearGradient {
        LinearGradient(colors: [skyTop, paper, skyBottom],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

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
                content.containerBackground(for: .widget) { WidgetPalette.sky }
            } else {
                content.background(WidgetPalette.sky)
            }
        default:
            content
        }
    }
}
