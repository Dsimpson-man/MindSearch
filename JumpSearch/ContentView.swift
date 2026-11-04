import SwiftUI
import UIKit
import WidgetKit

// MARK: - 风格：米黄纸张 + 墨色 + 衬线 / 等宽
enum Theme {
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.85)
    static let card = Color(red: 0.93, green: 0.89, blue: 0.80)
    static let ink = Color(red: 0.17, green: 0.13, blue: 0.10)
    static let faded = Color(red: 0.17, green: 0.13, blue: 0.10).opacity(0.5)

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

/// 按下去会轻轻缩一下的按钮
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - 纸张底纹

private struct PaperBackground: View {
    var body: some View {
        ZStack {
            Theme.paper
            Image(uiImage: Self.texture)
                .resizable(resizingMode: .tile)
                .opacity(0.55)
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }

    private static let texture: UIImage = {
        let size = CGSize(width: 220, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            for _ in 0..<900 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let alpha = CGFloat.random(in: 0.01...0.035)
                cg.setFillColor(UIColor(red: 0.35, green: 0.28, blue: 0.20, alpha: alpha).cgColor)
                cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
            for _ in 0..<30 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let width = CGFloat.random(in: 4...16)
                let alpha = CGFloat.random(in: 0.01...0.02)
                cg.setStrokeColor(UIColor(red: 0.35, green: 0.28, blue: 0.20, alpha: alpha).cgColor)
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
        if let d = UserDefaults.standard.data(forKey: "urlOverrides"),
           let v = try? JSONDecoder().decode([String: String].self, from: d) { urlOverrides = v }

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

private enum ListTab: String, CaseIterable, Identifiable {
    case search = "搜索"
    case ideas = "想法"
    case history = "记录"

    var id: String { rawValue }
}

private struct PendingWeb: Identifiable {
    let id = UUID()
    let destination: Destination
    let text: String
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var store = Store()
    @StateObject private var voice = VoiceInput()

    @State private var keyword = ""
    @State private var appText = ""
    @State private var keywordFocused = false
    @State private var appFocused = false
    @State private var keywordComposing = false
    @State private var appComposing = false

    @State private var tab: ListTab = .search
    @State private var message: String? = nil
    @State private var showSettings = false
    @State private var pendingWeb: PendingWeb? = nil

    @State private var showPanel = false
    @State private var panelKeyword = ""
    @State private var panelApp = ""
    @State private var panelKeywordFocused = false
    @State private var panelAppFocused = false
    @State private var panelKeywordComposing = false
    @State private var panelAppComposing = false

    @State private var voiceBase = ""
    @State private var pulse = false
    @State private var appeared = false

    // 小组件传进来的动作，等界面就绪后再执行
    @State private var pendingWidgetLink: WidgetDeepLink? = nil

    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            PaperBackground()
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
                        .font(Theme.mono(13))
                        .foregroundColor(Theme.paper)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.ink))
                        .padding(.bottom, 88)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: message)
        .animation(.easeOut(duration: 0.18), value: showSettings)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showPanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: tab)
        .animation(.easeInOut(duration: 0.2), value: voice.isRecording)
        .onChange(of: voice.isRecording) { recording in
            if recording {
                pulse = false
                DispatchQueue.main.async { pulse = true }
            } else {
                pulse = false
            }
        }
        .onAppear {
            if store.useDefaultApp, appText.isEmpty, !store.defaultAppName.isEmpty {
                appText = store.defaultAppName
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
            // 每次启动都聚焦应用槽；来自小组件时由 applyWidgetLink 决定焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard pendingWidgetLink == nil,
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
    }

    // MARK: - 顶部

    private var header: some View {
        ZStack {
            Text("MindSearch")
                .font(Theme.serif(20))
                .foregroundColor(Theme.ink)

            HStack {
                Spacer()
                Button {
                    dismissKeyboard()
                    showSettings = true
                } label: {
                    Text("设置")
                        .font(Theme.mono(12))
                        .foregroundColor(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Theme.ink.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 一句话输入区（搜索标签页）

    private var sentenceArea: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 16) {
                sentenceLine("用") { appField }
                sentenceLine("搜索") { keywordField }

                HStack(spacing: 12) {
                    micButton
                    Spacer(minLength: 8)
                    if showIdeaHint {
                        Text("\(trimmedKeyword.count) 字 · 回车存为想法")
                            .font(Theme.mono(11))
                            .foregroundColor(Theme.faded)
                            .lineLimit(1)
                    }
                    submitButton
                }
                .padding(.top, 4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .padding(.horizontal, 28)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sentenceLine<Content: View>(_ label: String,
                                             size: CGFloat = 30,
                                             @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(label)
                .font(Theme.serif(size))
                .foregroundColor(Theme.ink)
            Text("（")
                .font(Theme.serif(size + 6))
                .foregroundColor(Theme.ink)
            content()
            Text("）")
                .font(Theme.serif(size + 6))
                .foregroundColor(Theme.ink)
        }
    }

    private var appField: some View {
        AppNameField(
            text: $appText,
            focused: $appFocused,
            isComposing: $appComposing,
            font: Theme.serifUIFont(28),
            placeholder: "*app*",
            ghost: appFocused ? ghost(for: appText) : nil,
            onSubmit: { confirmApp() }
        )
        .frame(height: 46)
    }

    private var keywordField: some View {
        UIKitTextField(
            text: $keyword,
            isFocused: $keywordFocused,
            isComposing: $keywordComposing,
            placeholder: "*关键词*",
            font: Theme.serifUIFont(28),
            returnKey: .search,
            onSubmit: { submit() },
            onHoldStart: { beginHoldVoice() },
            onHoldEnd: { endHoldVoice() }
        )
        .frame(height: 46)
    }

    private var micButton: some View {
        Button {
            toggleVoice()
        } label: {
            Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(voice.isRecording ? Theme.paper : Theme.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(voice.isRecording ? Theme.ink : Color.clear))
                .overlay(Circle().stroke(Theme.ink.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(voice.isRecording ? "停止语音输入" : "语音输入")
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.paper)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.ink))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("搜索或存为想法")
    }

    // MARK: - 底部搜索面板

    private var panelOverlay: some View {
        ZStack(alignment: .bottom) {
            Theme.ink.opacity(0.18).ignoresSafeArea()
                .onTapGesture { closePanel() }

            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Theme.ink.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
                    .contentShape(Rectangle())
                    .gesture(DragGesture().onEnded { value in
                        if value.translation.height > 60 { closePanel() }
                    })

                HStack {
                    Text("去其他应用搜索")
                        .font(Theme.mono(13))
                        .foregroundColor(Theme.faded)
                    Spacer()
                    Button("关闭") { closePanel() }
                        .font(Theme.mono(12))
                        .foregroundColor(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Theme.ink.opacity(0.3), lineWidth: 1))
                        .buttonStyle(PressableStyle())
                }

                sentenceLine("用", size: 22) {
                    AppNameField(
                        text: $panelApp,
                        focused: $panelAppFocused,
                        isComposing: $panelAppComposing,
                        font: Theme.serifUIFont(22),
                        placeholder: "*app*",
                        ghost: panelAppFocused ? ghost(for: panelApp) : nil,
                        onSubmit: { confirmPanelApp() }
                    )
                    .frame(height: 40)
                }

                sentenceLine("搜索", size: 22) {
                    UIKitTextField(
                        text: $panelKeyword,
                        isFocused: $panelKeywordFocused,
                        isComposing: $panelKeywordComposing,
                        placeholder: "*关键词*",
                        font: Theme.serifUIFont(22),
                        returnKey: .search,
                        onSubmit: { panelSearch() }
                    )
                    .frame(height: 40)
                }

                HStack {
                    Spacer()
                    Button("搜索") { panelSearch() }
                        .font(Theme.mono(15, bold: true))
                        .foregroundColor(Theme.paper)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.ink))
                        .buttonStyle(PressableStyle())
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Theme.paper))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Theme.ink.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 内容区（三个标签页）

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch tab {
            case .search:
                sentenceArea
                    .transition(.opacity)
            case .ideas:
                ideasList
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.99)),
                        removal: .opacity
                    ))
            case .history:
                historyList
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.99)),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ideasList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if store.ideas.isEmpty {
                    emptyText("还没有想法。去搜索页写长一点，回车就会存下来。")
                }
                ForEach(store.ideas) { idea in
                    row(idea.text)
                        .onTapGesture { openPanel(keyword: idea.text, app: store.defaultAppName) }
                        .contextMenu {
                            Button("删除", role: .destructive) {
                                store.ideas.removeAll { $0.id == idea.id }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.ideas.removeAll { $0.id == idea.id }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(20)
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(store.history.count) 条")
                        .font(Theme.mono(12))
                        .foregroundColor(Theme.faded)
                    Spacer()
                    if !store.history.isEmpty {
                        Button("清空") { store.history.removeAll() }
                            .font(Theme.mono(12))
                            .foregroundColor(Theme.faded)
                    }
                }
                if store.history.isEmpty {
                    emptyText("搜过的内容会自动出现在这里。")
                }
                ForEach(store.history.prefix(50)) { h in
                    row(h.text, trailing: h.app)
                        .onTapGesture {
                            let app = destinations.first(where: { $0.name == h.app })?.name
                            openPanel(keyword: h.text, app: app ?? store.defaultAppName)
                        }
                        .contextMenu {
                            Button("删除", role: .destructive) {
                                store.history.removeAll { $0.id == h.id }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.history.removeAll { $0.id == h.id }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(20)
        }
    }

    // MARK: - 底部标签

    private var tabBar: some View {
        GeometryReader { geo in
            let indices = Array(ListTab.allCases.indices)
            let count = CGFloat(indices.count)
            let centers = indices.map { geo.size.width * (CGFloat($0) * 2 + 1) / (count * 2) }
            let selectedIndex = ListTab.allCases.firstIndex(of: tab) ?? 0

            ZStack {
                LiquidIndicator(centers: centers,
                                selectedIndex: selectedIndex,
                                height: geo.size.height)

                HStack(spacing: 0) {
                    ForEach(ListTab.allCases) { item in
                        Button {
                            dismissKeyboard()
                            tab = item
                        } label: {
                            Text(item.rawValue)
                                .font(Theme.mono(14, bold: tab == item))
                                .foregroundColor(tab == item ? Theme.paper : Theme.faded)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(item.rawValue)
                        .accessibilityAddTraits(tab == item ? .isSelected : [])
                    }
                }
            }
        }
        .frame(height: 48)
        .background(Theme.paper)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.ink.opacity(0.1)),
                 alignment: .top)
        .padding(.vertical, 8)
    }

    // MARK: - 解析

    private var trimmedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showIdeaHint: Bool {
        !trimmedKeyword.isEmpty && trimmedKeyword.count > store.ideaThreshold
    }

    private var defaultDestination: Destination? {
        guard !store.defaultAppName.isEmpty else { return nil }
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
        keywordFocused = true
        tap()
    }

    private func submit() {
        let text = trimmedKeyword
        guard !text.isEmpty else {
            flash("先写关键词")
            keywordFocused = true
            return
        }

        if text.count > store.ideaThreshold {
            saveIdea(text)
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

    private func saveIdea(_ text: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            store.ideas.insert(IdeaItem(text: text), at: 0)
            keyword = ""
        }
        tap(.medium)
        dismissKeyboard()
        flash("已存为想法")
    }

    private func search(_ d: Destination, _ text: String) {
        store.defaultAppName = d.name
        tap(.medium)
        dismissKeyboard()
        go(d, text)
    }

    // MARK: - 面板动作

    private func openPanel(keyword text: String, app: String?) {
        dismissKeyboard()
        panelKeyword = text
        panelApp = app ?? store.defaultAppName
        showPanel = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            panelAppFocused = true
        }
    }

    private func closePanel() {
        panelKeywordFocused = false
        panelAppFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
        panelKeywordFocused = true
        tap()
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

    /// 按住关键词区域说话
    private func beginHoldVoice() {
        guard !voice.isRecording, !voice.isStarting else { return }
        dismissKeyboard()
        voiceBase = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        voice.toggle(onText: { text in
            let base = voiceBase
            keyword = base.isEmpty ? text : base + " " + text
        }, onError: { message in
            flash(message)
        })
    }

    private func endHoldVoice() {
        voice.stop()
    }

    // MARK: - 小组件唤起

    /// 处理小组件传进来的链接；执行过一次就清掉，避免重复跳转
    private func applyWidgetLink(_ link: WidgetDeepLink) {
        pendingWidgetLink = nil
        dismissKeyboard()
        showPanel = false
        showSettings = false
        tab = .search

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
        guard let url = resolvedURL(for: d, text: text, web: false) else { return }

        if UIApplication.shared.canOpenURL(url) {
            store.history.insert(HistoryItem(text: text, app: d.name), at: 0)

            if d.copyOnOpen {
                // DeepSeek 这类 URL 带不进文字：先复制，再打开 App，用户进去粘贴
                UIPasteboard.general.string = text
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                flash("已复制关键词，去 \(d.name) 粘贴")
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

    // MARK: - 小组件

    private func row(_ text: String, trailing: String? = nil) -> some View {
        HStack {
            Text(text).font(Theme.mono(15)).foregroundColor(Theme.ink).lineLimit(2)
            Spacer()
            if let t = trailing {
                Text(t).font(Theme.mono(12)).foregroundColor(Theme.faded)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(13))
            .foregroundColor(Theme.faded)
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

// MARK: - 水滴融合标签指示器

private struct LiquidIndicator: View {
    let centers: [CGFloat]
    let selectedIndex: Int
    let height: CGFloat

    @State private var fromIndex = 0
    @State private var toIndex = 0
    @State private var lastChange = Date()
    @State private var ready = false

    private var ink: SIMD3<Float> { SIMD3(0.17, 0.13, 0.10) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let t = context.date.timeIntervalSince(lastChange)
            let p = springProgress(t)
            let main = lerp(centers[fromIndex], centers[toIndex], p)
            let trail = lerp(centers[fromIndex], centers[toIndex], max(0, p - 0.16))

            MetaballView(
                blobs: [
                    MetaballBlob(center: SIMD2(Float(main), Float(height / 2)), radius: 16, weight: 1.0),
                    MetaballBlob(center: SIMD2(Float(trail), Float(height / 2)), radius: 13, weight: 0.7)
                ],
                tint: ink
            )
        }
        .onAppear {
            toIndex = selectedIndex
            fromIndex = selectedIndex
            ready = true
        }
        .onChange(of: selectedIndex) { newValue in
            guard ready else { return }
            fromIndex = toIndex
            toIndex = newValue
            lastChange = Date()
        }
    }

    private func springProgress(_ t: TimeInterval) -> CGFloat {
        guard t > 0 else { return 0 }
        let p = 1 - exp(-7 * t) * cos(10 * t)
        return min(1.25, max(0, CGFloat(p)))
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

#Preview { ContentView() }
