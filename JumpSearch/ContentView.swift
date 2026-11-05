import SwiftUI
import UIKit
import WidgetKit

// MARK: - 风格：雾面莫兰迪（低饱和灰玫瑰 / 灰蓝 / 雾绿），衬线 + 等宽
//
// 底色不再是实色纸，而是「一层暖灰渐变 + 三团极慢漂移的雾」。
// 所有表面用磨砂玻璃，文字仍然压到接近炭黑，保证对比度。
enum Theme {
    // 底色
    static let paper = dynamic(light: (0.906, 0.898, 0.886),   // #E7E5E2 雾灰
                               dark:  (0.086, 0.082, 0.098))   // #161519 夜雾
    static let skyTop = dynamic(light: (0.929, 0.918, 0.902),  // #EDEAE6
                                dark:  (0.106, 0.102, 0.121))  // #1B1A1F
    static let skyBottom = dynamic(light: (0.867, 0.863, 0.863), // #DDDCDC
                                   dark:  (0.067, 0.063, 0.078)) // #111014
    static let ink = dynamic(light: (0.227, 0.216, 0.204),     // #3A3734
                             dark:  (0.902, 0.886, 0.867))     // #E6E2DD
    static let accent = dynamic(light: (0.463, 0.514, 0.463),  // #768376 雾绿灰
                                dark:  (0.678, 0.725, 0.667))  // #ADB9AA
    /// 实心按钮的底色：比 accent 更深一档，保证浅色文字的对比度
    static let accentFill = dynamic(light: (0.365, 0.412, 0.373),  // #5D6960
                                    dark:  (0.678, 0.725, 0.667))
    static let danger = dynamic(light: (0.600, 0.349, 0.322),  // #995956 灰砖红
                                dark:  (0.541, 0.310, 0.286))  // #8A4F49
    /// 红底上的字：不跟深色模式翻，否则会变成深底深字
    static let onDanger = Color(red: 0.957, green: 0.945, blue: 0.918)

    // 三团雾：只用来铺气氛，不承载信息
    static let hazeRose = dynamic(light: (0.847, 0.769, 0.741),  // 灰玫瑰
                                  dark:  (0.286, 0.208, 0.216))
    static let hazeBlue = dynamic(light: (0.729, 0.780, 0.808),  // 灰蓝
                                  dark:  (0.180, 0.220, 0.263))
    static let hazeSage = dynamic(light: (0.769, 0.800, 0.741),  // 雾绿
                                  dark:  (0.196, 0.239, 0.192))

    /// 面板背后压暗用：深色模式下必须用黑，否则会变成一层发光的纱
    static let scrim = Color(UIColor { trait in
        UIColor.black.withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.45 : 0.12)
    })

    static let faded = ink.opacity(0.60)      // 可读的次级文字
    static let hairline = ink.opacity(0.12)

    static let shadow = Color(UIColor { trait in
        UIColor.black.withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.45 : 0.10)
    })

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat),
                                dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }

    /// UIKit 控件用（UIColor(Color) 不会跟随深色模式，必须用动态 UIColor）
    static var inkUIColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.902, green: 0.886, blue: 0.867, alpha: 1)
            : UIColor(red: 0.227, green: 0.216, blue: 0.204, alpha: 1)
        }
    }

    static var accentUIColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.678, green: 0.725, blue: 0.667, alpha: 1)
            : UIColor(red: 0.463, green: 0.514, blue: 0.463, alpha: 1)
        }
    }

    static var placeholderUIColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.902, green: 0.886, blue: 0.867, alpha: 0.30)
            : UIColor(red: 0.227, green: 0.216, blue: 0.204, alpha: 0.30)
        }
    }

    static func mono(_ size: CGFloat, bold: Bool = false) -> Font {
        .system(size: size, weight: bold ? .bold : .regular, design: .monospaced)
    }

    static func serif(_ size: CGFloat) -> Font {
        .custom("Songti SC", size: size)
    }

    static func serifUIFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "Songti SC", size: size) ?? .systemFont(ofSize: size)
    }
}

// MARK: - 动效：全部弹簧 —— 越靠近手指越硬，越远越软

enum Motion {
    /// 按压：一下到底，指尖能感觉到
    static let press: Animation = .spring(response: 0.30, dampingFraction: 0.72)
    /// 状态切换 / 图标 / 输入框高度
    static let quick: Animation = .spring(response: 0.42, dampingFraction: 0.86)
    /// 页面进出
    static let page: Animation = .spring(response: 0.52, dampingFraction: 0.90)
    /// 面板升起
    static let panel: Animation = .spring(response: 0.55, dampingFraction: 0.84)
    /// 飞点
    static let fly: Animation = .spring(response: 0.46, dampingFraction: 0.80)
    /// 背景的雾：58 秒一个来回，慢到几乎察觉不到方向
    static let drift: Animation = .linear(duration: 58).repeatForever(autoreverses: true)

    /// 弹簧没有固定时长，需要延时的场合用这两个近似值
    static let quickDelay: Double = 0.42
    static let flyDelay: Double = 0.46
}

/// 按下去是「咔」的一下，不是陷进棉花
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - 主按钮：静止的环，有关键词时收紧成实心圆

private struct SubmitButton: View {
    let active: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        ZStack {
            // 外圈雾光：有关键词时铺开
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.accent.opacity(active ? 0.20 : 0.05), .clear],
                                   center: .center,
                                   startRadius: 16,
                                   endRadius: 58)
                )
                .frame(width: 116, height: 116)
                .scaleEffect(active ? 1 : 0.82)

            // 磨砂环
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 72, height: 72)
                .overlay(
                    Circle().strokeBorder(Theme.accent.opacity(active ? 0.40 : 0.20),
                                          lineWidth: 0.8)
                )

            Circle()
                .fill(active ? Theme.accentFill : Theme.ink.opacity(0.66))
                .frame(width: 46, height: 46)
                .scaleEffect(active ? 1 : 0.92)
                .shadow(color: Theme.accent.opacity(active ? 0.40 : 0), radius: 12, y: 3)

            Image(systemName: "arrow.right")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.paper)
        }
        .contentShape(Circle())
        .gesture(
            ExclusiveGesture(
                LongPressGesture(minimumDuration: 0.45),
                TapGesture()
            )
            .onEnded { value in
                switch value {
                case .first: onLongPress()
                case .second: onTap()
                }
            }
        )
        .animation(Motion.quick, value: active)
        .accessibilityElement()
        .accessibilityLabel("搜索")
        .accessibilityHint("长按存为想法")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityAction(named: "存为想法") { onLongPress() }
    }
}

// MARK: - 雾面底：一层渐变 + 三团极慢漂移的雾 + 极细颗粒

struct HazeBackground: View {
    /// 0…1：聚焦关键词时让雾稍微亮一点，像呼吸深了一口
    var emphasis: Double = 0

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, geo.size.height)
            let h = geo.size.height

            ZStack {
                LinearGradient(colors: [Theme.skyTop, Theme.paper, Theme.skyBottom],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)

                haze(Theme.hazeRose, diameter: w * 1.20)
                    .offset(x: -w * 0.36 + (drifting ? w * 0.09 : 0),
                            y: -h * 0.34 + (drifting ? h * 0.10 : 0))
                    .opacity(0.88 + emphasis * 0.12)
                    .scaleEffect(1 + emphasis * 0.04)
                    .animation(.spring(response: 0.9, dampingFraction: 0.9), value: emphasis)

                haze(Theme.hazeBlue, diameter: w * 1.10)
                    .offset(x: w * 0.40 - (drifting ? w * 0.11 : 0),
                            y: -h * 0.02 + (drifting ? h * 0.14 : 0))

                haze(Theme.hazeSage, diameter: w * 1.00)
                    .offset(x: -w * 0.14 + (drifting ? w * 0.15 : 0),
                            y: h * 0.36 - (drifting ? h * 0.11 : 0))

                // 四周压一点点，中间透气
                RadialGradient(colors: [.clear,
                                        Color.black.opacity(colorScheme == .dark ? 0.30 : 0.05)],
                               center: .center,
                               startRadius: w * 0.22,
                               endRadius: w * 0.82)

                // 颗粒：顺带压住大面积渐变的色带
                Image(uiImage: Self.texture)
                    .resizable(resizingMode: .tile)
                    .opacity(colorScheme == .dark ? 0.06 : 0.16)
                    .blendMode(.multiply)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Motion.drift) { drifting = true }
        }
    }

    private func haze(_ color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(colors: [color, color.opacity(0)],
                               center: .center,
                               startRadius: diameter * 0.06,
                               endRadius: diameter * 0.50)
            )
            .frame(width: diameter, height: diameter)
    }

    private static let texture: UIImage = {
        let size = CGSize(width: 220, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            for _ in 0..<700 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let alpha = CGFloat.random(in: 0.006...0.018)
                cg.setFillColor(UIColor(red: 0.23, green: 0.21, blue: 0.19, alpha: alpha).cgColor)
                cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
            for _ in 0..<30 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let width = CGFloat.random(in: 4...16)
                let alpha = CGFloat.random(in: 0.005...0.012)
                cg.setStrokeColor(UIColor(red: 0.23, green: 0.21, blue: 0.19, alpha: alpha).cgColor)
                cg.setLineWidth(0.6)
                cg.move(to: CGPoint(x: x, y: y))
                cg.addLine(to: CGPoint(x: x + width, y: y))
                cg.strokePath()
            }
        }
    }()
}

// MARK: - 数据
struct IdeaItem: Identifiable, Codable {
    var id = UUID()
    var text: String
}

struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var app: String
    var date = Date()
}

final class Store: ObservableObject {
    @Published var ideas: [IdeaItem] = [] { didSet { save() } }
    @Published var history: [HistoryItem] = [] { didSet { save() } }

    // 设置
    @Published var aliases: [String: String] = [:] { didSet { saveSettings() } }
    @Published var defaultAppName: String = "" { didSet { saveSettings() } }
    @Published var useDefaultApp: Bool = false { didSet { saveSettings() } }
    @Published var ideaThreshold: Int = 20 { didSet { saveSettings() } }
    @Published var urlOverrides: [String: String] = [:] { didSet { saveURLOverrides() } }

    init() {
        if let d = UserDefaults.standard.data(forKey: "ideas"),
           let v = try? JSONDecoder().decode([IdeaItem].self, from: d) { ideas = v }
        if let d = UserDefaults.standard.data(forKey: "history"),
           let v = try? JSONDecoder().decode([HistoryItem].self, from: d) { history = v }

        if let d = UserDefaults.standard.data(forKey: "aliases"),
           let v = try? JSONDecoder().decode([String: String].self, from: d) { aliases = v }
        defaultAppName = UserDefaults.standard.string(forKey: "defaultAppName") ?? ""
        useDefaultApp = UserDefaults.standard.bool(forKey: "useDefaultApp")
        if UserDefaults.standard.object(forKey: "ideaThreshold") != nil {
            ideaThreshold = UserDefaults.standard.integer(forKey: "ideaThreshold")
        }
        var loadedOverrides: [String: String] = [:]
        if let d = UserDefaults.standard.data(forKey: "urlOverrides"),
           let v = try? JSONDecoder().decode([String: String].self, from: d) {
            loadedOverrides = v
        }

        // 修一次旧数据：自定义模板里没有 {q} 的话，关键词永远带不进去。
        // 默认模板带占位符、自定义却没带的，判定为误删，清掉回落到默认值。
        var didRepairOverrides = false
        if !UserDefaults.standard.bool(forKey: "repairedMissingPlaceholder") {
            let broken = loadedOverrides.filter { name, template in
                guard let dest = destinations.first(where: { $0.name == name }) else { return false }
                return dest.appTemplate.contains("{q}") && !template.contains("{q}")
            }.map(\.key)

            if !broken.isEmpty {
                for name in broken { loadedOverrides.removeValue(forKey: name) }
                if let data = try? JSONEncoder().encode(loadedOverrides) {
                    UserDefaults.standard.set(data, forKey: "urlOverrides")
                }
                didRepairOverrides = true
            }
            UserDefaults.standard.set(true, forKey: "repairedMissingPlaceholder")
        }
        urlOverrides = loadedOverrides

        // 老用户升级后第一次启动，把已有数据补进 App Group，小组件不会空白
        SharedData.bootstrapIfNeeded(
            recentApps: SharedData.recentApps(from: history.map { ($0.text, $0.app) }),
            lastKeyword: history.first?.text,
            lastApp: history.first?.app.replacingOccurrences(of: " · 网页", with: ""),
            aliases: aliases,
            defaultAppName: defaultAppName,
            useDefaultApp: useDefaultApp,
            urlOverrides: urlOverrides
        )

        // 修复过的模板要同步给小组件，否则 App Group 里还是旧的
        if didRepairOverrides { publishToWidget() }
    }

    /// 把小组件需要的数据同步到 App Group，然后刷新时间线
    func publishToWidget() {
        SharedData.publish(
            recentApps: SharedData.recentApps(from: history.map { ($0.text, $0.app) }),
            lastKeyword: history.first?.text,
            lastApp: history.first?.app.replacingOccurrences(of: " · 网页", with: ""),
            aliases: aliases,
            defaultAppName: defaultAppName,
            useDefaultApp: useDefaultApp,
            urlOverrides: urlOverrides
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func save() {
        if let d = try? JSONEncoder().encode(ideas) { UserDefaults.standard.set(d, forKey: "ideas") }
        if let d = try? JSONEncoder().encode(history) { UserDefaults.standard.set(d, forKey: "history") }
        publishToWidget()
    }

    private func saveSettings() {
        if let d = try? JSONEncoder().encode(aliases) { UserDefaults.standard.set(d, forKey: "aliases") }
        UserDefaults.standard.set(defaultAppName, forKey: "defaultAppName")
        UserDefaults.standard.set(useDefaultApp, forKey: "useDefaultApp")
        UserDefaults.standard.set(ideaThreshold, forKey: "ideaThreshold")
        publishToWidget()
    }

    private func saveURLOverrides() {
        if let d = try? JSONEncoder().encode(urlOverrides) {
            UserDefaults.standard.set(d, forKey: "urlOverrides")
        }
        publishToWidget()
    }
}

private enum Screen: String, CaseIterable, Identifiable {
    case search = "搜索"
    case ideas = "想法"
    case history = "记录"

    var id: String { rawValue }

    /// 底部只放这两个入口，搜索是常驻的根页面
    static let secondary: [Screen] = [.ideas, .history]
}

private struct PendingWeb: Identifiable {
    let id = UUID()
    let destination: Destination
    let text: String
}

// MARK: - 记录锚点（存想法时飞向底部入口）

private struct AnchorFrames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private extension View {
    func anchorFrame(_ name: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: AnchorFrames.self,
                                       value: [name: proxy.frame(in: .named("root"))])
            }
        )
    }
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var store = Store()
    @StateObject private var voice = VoiceInput()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var keyword = ""
    @State private var keywordHeight: CGFloat = 42
    @State private var appText = ""
    @State private var keywordFocused = false
    @State private var appFocused = false
    @State private var keywordComposing = false
    @State private var appComposing = false

    @State private var screen: Screen = .search
    @State private var message: String? = nil
    @State private var showSettings = false
    @State private var pendingWeb: PendingWeb? = nil
    @State private var showClearConfirm = false

    @State private var showPanel = false
    @State private var panelKeyword = ""
    @State private var panelKeywordHeight: CGFloat = 38
    @State private var panelApp = ""
    @State private var panelKeywordFocused = false
    @State private var panelAppFocused = false
    @State private var panelKeywordComposing = false
    @State private var panelAppComposing = false

    @State private var editingIdea: UUID? = nil
    @State private var ideaDraft = ""
    @State private var ideaDraftHeight: CGFloat = 20
    @State private var ideaFocused = false
    @State private var ideaComposing = false

    @State private var voiceBase = ""
    @State private var appeared = false

    @State private var anchors: [String: CGRect] = [:]
    @State private var fly: CGFloat = 0

    // 小组件传进来的动作，等界面就绪后再执行
    @State private var pendingWidgetLink: WidgetDeepLink? = nil

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: 尺寸

    private var keywordUIFont: UIFont { Theme.serifUIFont(25) }
    private let keywordMinHeight: CGFloat = 42
    private let keywordMaxHeight: CGFloat = 108

    private var keywordLabelTop: CGFloat {
        FieldMetrics.labelTop(fieldFont: keywordUIFont,
                              minHeight: keywordMinHeight,
                              labelFont: Theme.serifUIFont(19))
    }

    private var panelKeywordUIFont: UIFont { Theme.serifUIFont(21) }
    private let panelKeywordMinHeight: CGFloat = 38
    private let panelKeywordMaxHeight: CGFloat = 96

    private var panelKeywordLabelTop: CGFloat {
        FieldMetrics.labelTop(fieldFont: panelKeywordUIFont,
                              minHeight: panelKeywordMinHeight,
                              labelFont: Theme.serifUIFont(16))
    }

    private var ideaUIFont: UIFont { Theme.serifUIFont(15.5) }
    private let ideaLineSpacing: CGFloat = 8

    private func animate(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }

    var body: some View {
        ZStack {
            HazeBackground(emphasis: keywordFocused ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }

            VStack(spacing: 0) {
                header
                content
                tabBar
            }

            if let msg = message {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(Theme.mono(12))
                        .foregroundColor(Theme.ink)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(.regularMaterial))
                        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 0.75))
                        .shadow(color: Theme.shadow, radius: 18, y: 6)
                        .padding(.bottom, 82)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if fly > 0,
               let from = anchors["submit"],
               let to = anchors["ideasTab"] {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 7, height: 7)
                    .position(
                        x: from.midX + (to.midX - from.midX) * fly,
                        y: from.midY + (to.midY - from.midY) * fly - sin(fly * .pi) * 22
                    )
                    .allowsHitTesting(false)
            }

            if showSettings {
                SettingsView(store: store) {
                    showSettings = false
                    if store.useDefaultApp, appText.isEmpty, !store.defaultAppName.isEmpty {
                        appText = store.defaultAppName
                    }
                }
                .transition(.opacity)
                .zIndex(3)
            }

            if showPanel {
                panelOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(4)
            }

            if !hasSeenOnboarding {
                OnboardingView(threshold: store.ideaThreshold) {
                    withAnimation(animate(Motion.page)) {
                        hasSeenOnboarding = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appFocused = true
                    }
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .coordinateSpace(name: "root")
        .onPreferenceChange(AnchorFrames.self) { anchors = $0 }
        .animation(animate(Motion.quick), value: message)
        .animation(animate(Motion.page), value: showSettings)
        .animation(reduceMotion ? nil : Motion.panel, value: showPanel)
        .animation(animate(Motion.page), value: screen)
        .animation(animate(Motion.quick), value: voice.isRecording)
        .onAppear {
            if store.useDefaultApp, appText.isEmpty, !store.defaultAppName.isEmpty {
                appText = store.defaultAppName
            }
            withAnimation(animate(Motion.fly)) { appeared = true }
            // 每次启动都聚焦应用槽；引导、小组件、面板打开时不抢焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard hasSeenOnboarding,
                      pendingWidgetLink == nil,
                      !keywordFocused,
                      !showPanel && !showSettings else { return }
                appFocused = true
            }
        }
        .onDisappear { voice.stop() }
        .onOpenURL { url in
            guard let link = WidgetDeepLink(url: url) else { return }
            pendingWidgetLink = link
            // 等界面就绪后统一处理；applyWidgetLink 会清空 pending，不会重复执行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if let pending = pendingWidgetLink { applyWidgetLink(pending) }
            }
        }
        .onChange(of: appeared) { ready in
            guard ready, pendingWidgetLink != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if let link = pendingWidgetLink { applyWidgetLink(link) }
            }
        }
        .alert(item: $pendingWeb) { pending in
            Alert(
                title: Text("没装 \(pending.destination.name)"),
                message: Text("要用网页搜索吗？"),
                primaryButton: .default(Text("用网页搜索")) { openWeb(pending) },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .confirmationDialog("清空全部记录？",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("清空 \(store.history.count) 条记录", role: .destructive) {
                clearHistory()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("记录里的关键词和对应应用都会删除，不能恢复。")
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            if screen != .search {
                Button {
                    dismissKeyboard()
                    screen = .search
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("搜索")
                            .font(Theme.mono(12))
                    }
                    .foregroundColor(Theme.faded)
                    .frame(height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("返回搜索")
            }

            Spacer()

            Button {
                dismissKeyboard()
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.faded)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("设置")
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 0)
    }

    // MARK: - 一句话输入区

    private var sentenceArea: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 18) {
                    sentenceLine("用", active: appFocused) { appField }
                    keywordLine
                }

                recentAppsRow

                HStack(alignment: .center, spacing: 12) {
                    micButton
                    Spacer(minLength: 8)
                    if showIdeaButton {
                        Button {
                            saveIdea(trimmedKeyword)
                        } label: {
                            Text("存为想法")
                                .font(Theme.mono(11))
                                .foregroundColor(Theme.accentFill)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 2)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityHint("也可以长按右边的搜索按钮")
                    }
                    submitButton
                }
                .padding(.top, 4)
            }
            .animation(animate(Motion.quick), value: showRecentApps)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sentenceLine<Content: View>(_ label: String,
                                             size: CGFloat = 19,
                                             active: Bool = false,
                                             @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(label)
                .font(Theme.serif(size))
                .foregroundColor(Theme.faded)
                .frame(width: 40, alignment: .leading)
            content()
        }
        .padding(.bottom, 9)
        .overlay(alignment: .bottom) { rule(active: active) }
    }

    /// 多行输入行：标签对齐第一行文字，下划线跟着输入框的底边走
    private func multilineLine<Content: View>(_ label: String,
                                              size: CGFloat,
                                              labelTop: CGFloat,
                                              active: Bool = false,
                                              @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(Theme.serif(size))
                .foregroundColor(Theme.faded)
                .frame(width: 40, alignment: .leading)
                .padding(.top, labelTop)
            content()
        }
        .padding(.bottom, 9)
        .overlay(alignment: .bottom) { rule(active: active) }
    }

    /// 细线 + 聚焦时从左边长出来的一道雾光
    private func rule(active: Bool) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 0.5)

            LinearGradient(colors: [Theme.accent.opacity(0.85), Theme.accent.opacity(0)],
                           startPoint: .leading,
                           endPoint: .trailing)
                .frame(height: 1.2)
                .scaleEffect(x: active ? 1 : 0.001, anchor: .leading)
                .opacity(active ? 1 : 0)
        }
        .animation(animate(Motion.quick), value: active)
    }

    private var appField: some View {
        AppNameField(
            text: $appText,
            focused: $appFocused,
            isComposing: $appComposing,
            font: Theme.serifUIFont(25),
            placeholder: "应用名",
            ghost: appFocused ? ghost(for: appText) : nil,
            onSubmit: { confirmApp() }
        )
        .frame(height: 42)
    }

    private var keywordLine: some View {
        multilineLine("搜索", size: 19, labelTop: keywordLabelTop, active: keywordFocused) {
            GrowingTextView(
                text: $keyword,
                isFocused: $keywordFocused,
                isComposing: $keywordComposing,
                height: $keywordHeight,
                placeholder: "想搜什么",
                font: keywordUIFont,
                minHeight: keywordMinHeight,
                maxHeight: keywordMaxHeight,
                onSubmit: { submit() }
            )
            .frame(height: keywordHeight)
            .animation(animate(Motion.quick), value: keywordHeight)
        }
    }

    /// 应用槽空着、还没开始打字时，给三个最近用过的应用
    @ViewBuilder
    private var recentAppsRow: some View {
        if showRecentApps {
            HStack(spacing: 14) {
                Text("最近")
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.faded)

                ForEach(recentApps, id: \.self) { name in
                    Button {
                        pickRecent(name)
                    } label: {
                        Text(name)
                            .font(Theme.mono(11))
                            .foregroundColor(Theme.accentFill)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 56)
            .transition(.opacity)
        }
    }

    private var micButton: some View {
        Button {
            toggleVoice()
        } label: {
            Image(systemName: voice.isRecording ? "stop.fill" : "mic")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(voice.isRecording ? Theme.paper : Theme.accent)
                .frame(width: 42, height: 42)
                .background(Circle().fill(voice.isRecording ? Theme.accentFill : Color.clear))
                .overlay(Circle().stroke(Theme.accent.opacity(0.35), lineWidth: 0.8))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(voice.isRecording ? "停止语音输入" : "语音输入")
    }

    private var submitButton: some View {
        SubmitButton(active: !trimmedKeyword.isEmpty,
                     onTap: { submit() },
                     onLongPress: { submitAsIdea() })
            .anchorFrame("submit")
    }

    // MARK: - 底部搜索面板

    private var panelOverlay: some View {
        ZStack(alignment: .bottom) {
            Theme.scrim.ignoresSafeArea()
                .onTapGesture { closePanel() }

            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Theme.ink.opacity(0.12))
                    .frame(width: 32, height: 3)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                    .contentShape(Rectangle())
                    .gesture(DragGesture().onEnded { value in
                        if value.translation.height > 60 { closePanel() }
                    })

                HStack {
                    Text("换个应用")
                        .font(Theme.serif(17))
                        .foregroundColor(Theme.ink)
                    Spacer()
                    Button("关闭") { closePanel() }
                        .font(Theme.mono(11))
                        .foregroundColor(Theme.faded)
                        .buttonStyle(PressableStyle())
                }

                sentenceLine("用", size: 16, active: panelAppFocused) {
                    AppNameField(
                        text: $panelApp,
                        focused: $panelAppFocused,
                        isComposing: $panelAppComposing,
                        font: Theme.serifUIFont(21),
                        placeholder: "应用名",
                        ghost: panelAppFocused ? ghost(for: panelApp) : nil,
                        onSubmit: { confirmPanelApp() }
                    )
                    .frame(height: 38)
                }

                multilineLine("搜索", size: 16, labelTop: panelKeywordLabelTop, active: panelKeywordFocused) {
                    GrowingTextView(
                        text: $panelKeyword,
                        isFocused: $panelKeywordFocused,
                        isComposing: $panelKeywordComposing,
                        height: $panelKeywordHeight,
                        placeholder: "想搜什么",
                        font: panelKeywordUIFont,
                        minHeight: panelKeywordMinHeight,
                        maxHeight: panelKeywordMaxHeight,
                        onSubmit: { panelSearch() }
                    )
                    .frame(height: panelKeywordHeight)
                    .animation(animate(Motion.quick), value: panelKeywordHeight)
                }

                HStack {
                    Spacer()
                    Button("搜索") { panelSearch() }
                        .font(Theme.mono(13, bold: true))
                        .foregroundColor(Theme.paper)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accentFill))
                        .buttonStyle(PressableStyle())
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Theme.shadow, radius: 32, x: 0, y: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 0.8)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 内容区

    /// 页面之间交叉淡入 + 一点点缩放，不做横向位移（两个页面是平级的）
    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.985)),
            removal: .opacity
        )
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch screen {
            case .search:
                sentenceArea
                    .transition(pageTransition)
            case .ideas:
                ideasList
                    .transition(pageTransition)
            case .history:
                historyList
                    .transition(pageTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 想法（卡片，就地编辑）

    private var ideasList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if store.ideas.isEmpty {
                    emptyState("还没有想法。\n写得长一点，右下角会出现「存为想法」。")
                }
                ForEach(store.ideas) { idea in
                    ideaCard(idea)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
    }

    private func ideaCard(_ idea: IdeaItem) -> some View {
        let editing = editingIdea == idea.id

        return VStack(alignment: .leading, spacing: 10) {
            if editing {
                GrowingTextView(
                    text: $ideaDraft,
                    isFocused: $ideaFocused,
                    isComposing: $ideaComposing,
                    height: $ideaDraftHeight,
                    placeholder: "",
                    font: ideaUIFont,
                    minHeight: ceil(ideaUIFont.lineHeight),
                    maxHeight: 180,
                    lineSpacing: ideaLineSpacing,
                    onSubmit: { commitIdeaEdit() }
                )
                .frame(height: ideaDraftHeight)
                .animation(animate(Motion.quick), value: ideaDraftHeight)
            } else {
                Text(idea.text)
                    .font(Theme.serif(15.5))
                    .lineSpacing(ideaLineSpacing)
                    .foregroundColor(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Spacer(minLength: 0)
                if editing {
                    Button("完成") { commitIdeaEdit() }
                        .accessibilityLabel("完成编辑")
                } else {
                    Button {
                        deleteIdea(idea)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .frame(width: 32, height: 26)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("删除这条想法")
                }
            }
            .font(Theme.mono(10))
            .foregroundColor(Theme.faded)
        }
        .padding(.horizontal, 18)
        .padding(.top, 17)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.shadow, radius: editing ? 18 : 10, y: editing ? 8 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 0.8)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            if !editing { beginIdeaEdit(idea) }
        }
        .contextMenu {
            Button("删除", role: .destructive) { deleteIdea(idea) }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .animation(animate(Motion.quick), value: editing)
    }

    // MARK: - 记录（行，左滑删除）

    private var historyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(store.history.count) 条")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.faded)
                    Spacer()
                    if !store.history.isEmpty {
                        Button("清空") { showClearConfirm = true }
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.faded)
                            .buttonStyle(PressableStyle())
                    }
                }
                .padding(.bottom, 4)

                if store.history.isEmpty {
                    emptyState("搜过的内容会安静地留在这里。")
                }

                ForEach(historyGroups, id: \.title) { group in
                    Text(group.title)
                        .font(Theme.mono(9))
                        .tracking(1.8)
                        .foregroundColor(Theme.faded)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    ForEach(group.items) { h in
                        SwipeRow(onDelete: { deleteHistory(h) }) {
                            listRow(h.text, trailing: h.app)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let app = destinations.first(where: { $0.name == h.app })?.name
                            openPanel(keyword: h.text,
                                      app: app
                                        ?? recentApps.first
                                        ?? (store.useDefaultApp ? store.defaultAppName : ""))
                        }
                        .contextMenu {
                            Button("删除", role: .destructive) { deleteHistory(h) }
                        }
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
    }

    private struct HistoryGroup {
        let title: String
        let items: [HistoryItem]
    }

    private var historyGroups: [HistoryGroup] {
        var today: [HistoryItem] = []
        var yesterday: [HistoryItem] = []
        var earlier: [HistoryItem] = []
        for item in store.history.prefix(50) {
            if Calendar.current.isDateInToday(item.date) {
                today.append(item)
            } else if Calendar.current.isDateInYesterday(item.date) {
                yesterday.append(item)
            } else {
                earlier.append(item)
            }
        }
        return [("今天", today), ("昨天", yesterday), ("更早", earlier)]
            .filter { !$0.1.isEmpty }
            .map { HistoryGroup(title: $0.0, items: $0.1) }
    }

    // MARK: - 底部标签

    private var tabBar: some View {
        HStack(spacing: 72) {
            ForEach(Screen.secondary) { item in
                let selected = screen == item
                Button {
                    dismissKeyboard()
                    if selected {
                        // 再点一次当前入口就回到搜索
                        screen = .search
                    } else {
                        UISelectionFeedbackGenerator().selectionChanged()
                        screen = item
                    }
                } label: {
                    VStack(spacing: 5) {
                        Circle()
                            .fill(selected ? Theme.accentFill : Color.clear)
                            .frame(width: 3, height: 3)
                        Text(item.rawValue)
                            .font(Theme.mono(12))
                            .foregroundColor(selected ? Theme.accentFill : Theme.ink.opacity(0.62))
                    }
                    .frame(minWidth: 64)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .anchorFrame(item == .ideas ? "ideasTab" : "historyTab")
                .accessibilityLabel(item.rawValue)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 0.5)
        }
    }

    // MARK: - 解析

    private var trimmedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 超过阈值才露出「存为想法」——回车永远是搜索
    private var showIdeaButton: Bool {
        trimmedKeyword.count > store.ideaThreshold
    }

    private var recentApps: [String] {
        var result: [String] = []
        for item in store.history.prefix(60) {
            let name = item.app.replacingOccurrences(of: " · 网页", with: "")
            guard destinations.contains(where: { $0.name == name }) else { continue }
            if !result.contains(name) { result.append(name) }
            if result.count >= 3 { break }
        }
        return result
    }

    private var showRecentApps: Bool {
        appText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && trimmedKeyword.isEmpty
            && !recentApps.isEmpty
    }

    /// 只有打开「启用默认 APP」时，空着的应用槽才落到默认应用
    private var defaultDestination: Destination? {
        guard store.useDefaultApp, !store.defaultAppName.isEmpty else { return nil }
        return destinations.first { $0.name == store.defaultAppName }
    }

    /// 应用框里输入的文字 -> 应用；空着就用默认应用
    private func resolveApp(_ raw: String) -> Destination? {
        let typed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty { return defaultDestination }
        if let exact = destinations.first(where: { $0.name == typed }) { return exact }

        let lower = typed.lowercased()
        return destinations.first { d in
            d.matchKeys(alias: store.aliases[d.name])
                .contains { $0.lowercased().hasPrefix(lower) }
        }
    }

    /// 幽灵预览：输入 xh / xy / xhs 时返回对应应用名；已经打全了名字就不预览
    private func ghost(for raw: String) -> String? {
        let typed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty else { return nil }
        let lower = typed.lowercased()

        guard let match = destinations.first(where: { d in
            d.matchKeys(alias: store.aliases[d.name])
                .contains { $0.lowercased().hasPrefix(lower) }
        }), match.name != typed else { return nil }

        return match.name
    }

    // MARK: - 动作

    private func confirmApp() {
        let typed = appText.trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            appFocused = false
            keywordFocused = true
            return
        }
        guard let d = resolveApp(typed) else {
            flash("没找到这个应用")
            return
        }
        appText = d.name
        appFocused = false
        tap()

        // 关键词已经填好时，确认应用就直接搜；空着才把焦点交给关键词
        if trimmedKeyword.isEmpty {
            keywordFocused = true
        } else {
            submit()
        }
    }

    /// 回车 = 搜索，任何长度都一样
    private func submit() {
        let text = trimmedKeyword
        guard !text.isEmpty else {
            flash("先写关键词")
            keywordFocused = true
            return
        }

        if let d = resolveApp(appText) {
            search(d, text)
        } else if !appText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            flash("没找到这个应用")
            appFocused = true
        } else {
            flash("先选一个应用")
            appFocused = true
        }
    }

    /// 长按主按钮：不看长度，直接存
    private func submitAsIdea() {
        let text = trimmedKeyword
        guard !text.isEmpty else {
            flash("先写关键词")
            keywordFocused = true
            return
        }
        saveIdea(text)
    }

    private func saveIdea(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(animate(Motion.quick)) {
            store.ideas.insert(IdeaItem(text: trimmed), at: 0)
            keyword = ""
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismissKeyboard()
        flash("已存为想法")
        flyToInbox()
    }

    private func flyToInbox() {
        guard !reduceMotion,
              anchors["submit"] != nil,
              anchors["ideasTab"] != nil else { return }
        // 先让圆点以「起点」姿态进入视图，再动画到终点
        fly = 0.001
        DispatchQueue.main.async {
            withAnimation(Motion.fly) { fly = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Motion.flyDelay + 0.05) {
            fly = 0
        }
    }

    private func search(_ d: Destination, _ text: String) {
        tap(.light)
        dismissKeyboard()
        go(d, text)
    }

    private func pickRecent(_ name: String) {
        appText = name
        appFocused = false
        keywordFocused = true
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - 想法编辑

    private func beginIdeaEdit(_ idea: IdeaItem) {
        if editingIdea != nil { commitIdeaEdit() }
        dismissKeyboard()
        ideaDraft = idea.text
        ideaDraftHeight = ceil(ideaUIFont.lineHeight)
        editingIdea = idea.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            ideaFocused = true
        }
    }

    private func commitIdeaEdit() {
        guard let id = editingIdea else { return }
        let text = ideaDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, let index = store.ideas.firstIndex(where: { $0.id == id }) {
            store.ideas[index].text = text
        }
        editingIdea = nil
        ideaDraft = ""
        ideaFocused = false
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func deleteIdea(_ idea: IdeaItem) {
        if editingIdea == idea.id { editingIdea = nil }
        withAnimation(animate(Motion.quick)) {
            store.ideas.removeAll { $0.id == idea.id }
        }
        tap()
    }

    private func deleteHistory(_ item: HistoryItem) {
        withAnimation(animate(Motion.quick)) {
            store.history.removeAll { $0.id == item.id }
        }
        tap()
    }

    private func clearHistory() {
        withAnimation(animate(Motion.quick)) {
            store.history.removeAll()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - 面板动作

    private func openPanel(keyword text: String, app: String?) {
        dismissKeyboard()
        panelKeyword = text
        panelKeywordHeight = panelKeywordMinHeight
        panelApp = app ?? ""
        showPanel = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            panelAppFocused = true
        }
    }

    private func closePanel() {
        panelKeywordFocused = false
        panelAppFocused = false
        withAnimation(reduceMotion ? nil : Motion.panel) {
            showPanel = false
        }
    }

    private func confirmPanelApp() {
        let typed = panelApp.trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            panelAppFocused = false
            panelKeywordFocused = true
            return
        }
        guard let d = resolveApp(typed) else {
            flash("没找到这个应用")
            return
        }
        panelApp = d.name
        panelAppFocused = false
        tap()

        // 从记录 / 想法进来时关键词已经填好，换完应用直接搜，不再跳关键词
        if panelKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            panelKeywordFocused = true
        } else {
            panelSearch()
        }
    }

    private func panelSearch() {
        let text = panelKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            flash("先写关键词")
            panelKeywordFocused = true
            return
        }
        guard let d = resolveApp(panelApp) else {
            flash(panelApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                  ? "先选一个应用" : "没找到这个应用")
            panelAppFocused = true
            return
        }
        closePanel()
        search(d, text)
    }

    // MARK: - 语音 / 跳转

    private func toggleVoice() {
        if voice.isRecording || voice.isStarting {
            voice.stop()
            return
        }
        dismissKeyboard()
        voiceBase = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        voice.toggle(onText: { text in
            let base = voiceBase
            keyword = base.isEmpty ? text : base + " " + text
        }, onError: { message in
            flash(message)
        })
    }

    // MARK: - 小组件唤起

    /// 处理小组件传进来的链接；执行过一次就清掉，避免重复跳转
    private func applyWidgetLink(_ link: WidgetDeepLink) {
        pendingWidgetLink = nil
        dismissKeyboard()
        showPanel = false
        showSettings = false
        screen = .search

        if let name = link.appName {
            if let d = destinations.first(where: { $0.name == name }) {
                appText = d.name
            } else {
                appText = name
                flash("没找到 \(name)")
                return
            }
        } else if store.useDefaultApp, !store.defaultAppName.isEmpty {
            appText = store.defaultAppName
        } else {
            appText = ""
        }

        if let keyword = link.keyword {
            self.keyword = keyword
            guard let d = resolveApp(appText) else {
                flash("没找到这个应用")
                appFocused = true
                return
            }
            if link.forceWeb {
                openWeb(PendingWeb(destination: d, text: keyword))
            } else {
                search(d, keyword)
            }
        } else {
            // 没带关键词：只把应用填好，聚焦关键词框，等用户输入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                keywordFocused = true
            }
        }
    }

    private func resolvedURL(for d: Destination, text: String, web: Bool) -> URL? {
        if let override = store.urlOverrides[d.name], !override.isEmpty {
            return URL(string: override.replacingOccurrences(of: "{q}", with: encodeQuery(text)))
        }
        return URL(string: web ? d.webURL(text) : d.appURL(text))
    }

    private func go(_ d: Destination, _ text: String) {
        guard let url = resolvedURL(for: d, text: text, web: false) else {
            flash("这个应用的跳转地址无效")
            return
        }

        // 模板里没有 {q} 时，关键词根本进不去，只能退回剪贴板
        let template = store.urlOverrides[d.name] ?? d.appTemplate
        let needsClipboard = d.copyOnOpen || !template.contains("{q}")

        if UIApplication.shared.canOpenURL(url) {
            store.history.insert(HistoryItem(text: text, app: d.name), at: 0)

            if needsClipboard {
                // DeepSeek 这类 URL 带不进文字：先复制，再打开 App，用户进去粘贴
                UIPasteboard.general.string = text
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                flash(d.copyOnOpen
                      ? "已复制关键词，去 \(d.name) 粘贴"
                      : "跳转地址缺少 {q}，关键词已复制")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    UIApplication.shared.open(url)
                }
            } else {
                UIApplication.shared.open(url)
            }
        } else {
            pendingWeb = PendingWeb(destination: d, text: text)
        }
    }

    private func openWeb(_ pending: PendingWeb) {
        guard let url = resolvedURL(for: pending.destination, text: pending.text, web: true) else { return }
        store.history.insert(
            HistoryItem(text: pending.text, app: pending.destination.name + " · 网页"),
            at: 0
        )
        UIApplication.shared.open(url)
    }

    private func dismissKeyboard() {
        keywordFocused = false
        appFocused = false
        panelKeywordFocused = false
        panelAppFocused = false
        ideaFocused = false
        if editingIdea != nil { commitIdeaEdit() }
    }

    private func flash(_ text: String) {
        message = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if message == text { message = nil }
        }
    }

    private func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - 列表行

    private func listRow(_ text: String, trailing: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(text)
                .font(Theme.mono(14))
                .foregroundColor(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            if let t = trailing {
                Text(t)
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.faded)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 0.5)
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(Theme.serif(16))
            .foregroundColor(Theme.faded)
            .multilineTextAlignment(.center)
            .lineSpacing(7)
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .center)
    }
}

// MARK: - 左滑删除（自建手势，保留无边框 + 细线的排版）

private struct SwipeRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var dragging = false

    private let threshold: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                Rectangle()
                    .fill(Theme.danger)
                    .frame(width: -offset)
                    .overlay(alignment: .trailing) {
                        Text("删除")
                            .font(Theme.mono(12))
                            .foregroundColor(Theme.onDanger)
                            .padding(.trailing, 20)
                    }
                    .clipped()
            }

            content()
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            dragging = true
                            offset = min(0, value.translation.width)
                        }
                        .onEnded { _ in
                            guard dragging else { return }
                            dragging = false
                            if offset < -threshold {
                                withAnimation(Motion.quick) {
                                    offset = -420
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + Motion.quickDelay) {
                                    onDelete()
                                    offset = 0
                                }
                            } else {
                                withAnimation(Motion.quick) {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipped()
        .accessibilityAction(named: "删除") { onDelete() }
    }
}

// MARK: - 应用名输入框（带幽灵预览）

private struct AppNameField: View {
    @Binding var text: String
    @Binding var focused: Bool
    @Binding var isComposing: Bool
    let font: UIFont
    let placeholder: String
    let ghost: String?
    let onSubmit: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            UIKitTextField(
                text: $text,
                isFocused: $focused,
                isComposing: $isComposing,
                placeholder: placeholder,
                font: font,
                returnKey: .go,
                onSubmit: onSubmit
            )

            if let ghost, !ghost.isEmpty {
                Text(" " + ghost)
                    .font(Theme.serif(font.pointSize))
                    .foregroundColor(Theme.faded)
                    .fixedSize()
                    .offset(x: textWidth)
                    .onTapGesture { onSubmit() }
                    .transition(.opacity)
            }
        }
        .clipped()
        .animation(.easeOut(duration: 0.12), value: ghost)
    }

    private var textWidth: CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }
}

#Preview { ContentView() }
