import SwiftUI
import UIKit

/// 设置：默认应用、想法判定字数、每个应用的别名。
struct SettingsView: View {
    @ObservedObject var store: Store
    let onClose: () -> Void

    @State private var editingApp: Destination? = nil
    @State private var aliasDraft = ""
    @State private var editingURLApp: Destination? = nil

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 0.5)

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        defaultAppSection
                        thresholdSection
                        aliasSection
                    }
                    .padding(20)
                }
            }
        }
        .alert("设置别名", isPresented: aliasAlertBinding) {
            TextField("别名，例如 xhs", text: $aliasDraft)
            Button("保存") { saveAlias() }
            Button("取消", role: .cancel) { editingApp = nil }
        } message: {
            Text("用别名也能识别，留空则清除。")
        }
        .sheet(item: $editingURLApp) { d in
            URLTemplateEditor(
                appName: d.name,
                template: store.urlOverrides[d.name] ?? d.appTemplate,
                defaultTemplate: d.appTemplate,
                copiesToClipboard: d.copyOnOpen
            ) { value in
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed == d.appTemplate {
                    store.urlOverrides.removeValue(forKey: d.name)
                } else {
                    store.urlOverrides[d.name] = trimmed
                }
                editingURLApp = nil
            }
        }
    }

    private var header: some View {
        HStack {
            Text("设置")
                .font(Theme.serif(22))
                .foregroundColor(Theme.ink)
            Spacer()
            Button(action: onClose) {
                Text("关闭")
                    .font(Theme.mono(11))
                    .foregroundColor(Theme.faded)
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("关闭设置")
        }
    }

    private var defaultAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("默认 APP")
            Text("启动时自动填入应用槽；应用槽空着时也用它搜索。")
                .font(Theme.mono(11))
                .foregroundColor(Theme.faded)
                .fixedSize(horizontal: false, vertical: true)

            toggleRow("启用默认 APP", isOn: $store.useDefaultApp)

            HStack {
                Text("默认 APP")
                    .font(Theme.mono(15))
                    .foregroundColor(Theme.ink)
                Spacer()
                Menu {
                    ForEach(destinations) { d in
                        Button(d.name) { store.defaultAppName = d.name }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(store.defaultAppName.isEmpty ? "未设置" : store.defaultAppName)
                            .font(Theme.mono(14))
                            .foregroundColor(Theme.ink)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.faded)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().stroke(Theme.ink.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }

    private var thresholdSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("想法判定")
            Text("超过这个字数，右下角出现「存为想法」。回车永远是搜索。")
                .font(Theme.mono(11))
                .foregroundColor(Theme.faded)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("\(store.ideaThreshold) 字")
                    .font(Theme.mono(15))
                    .foregroundColor(Theme.ink)
                Spacer()
                Stepper("", value: $store.ideaThreshold, in: 10...40)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .padding(.vertical, 4)
        }
    }

    private var aliasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("别名")
            Text("点一下改别名，长按改跳转地址。")
                .font(Theme.mono(11))
                .foregroundColor(Theme.faded)

            ForEach(AppCategory.allCases) { category in
                let items = destinations.filter { $0.category == category }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(Theme.mono(12))
                            .foregroundColor(Theme.faded)
                            .padding(.top, 6)

                        VStack(spacing: 0) {
                            ForEach(items) { d in
                                Button {
                                    beginEditing(d)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(d.name)
                                            .font(Theme.mono(15))
                                            .foregroundColor(Theme.ink)
                                        if d.copyOnOpen {
                                            Image(systemName: "doc.on.clipboard")
                                                .font(.system(size: 10))
                                                .foregroundColor(Theme.faded)
                                                .accessibilityLabel("会复制到剪贴板")
                                        }
                                        Spacer()
                                        Text(aliasLabel(for: d))
                                            .font(Theme.mono(12))
                                            .foregroundColor(Theme.faded)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(
                                    LongPressGesture(minimumDuration: 0.5)
                                        .onEnded { _ in editingURLApp = d }
                                )

                                if d.id != items.last?.id {
                                    Rectangle()
                                        .fill(Theme.hairline)
                                        .frame(height: 0.5)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.card))
                    }
                }
            }
        }
    }

    // MARK: - 小组件

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(10))
            .tracking(1.6)
            .foregroundColor(Theme.faded)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(Theme.mono(15))
                .foregroundColor(Theme.ink)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.vertical, 4)
    }

    private func aliasLabel(for d: Destination) -> String {
        if let alias = store.aliases[d.name], !alias.isEmpty {
            return alias
        }
        return "＋"
    }

    // MARK: - 别名编辑

    private var aliasAlertBinding: Binding<Bool> {
        Binding(
            get: { editingApp != nil },
            set: { if !$0 { editingApp = nil } }
        )
    }

    private func beginEditing(_ d: Destination) {
        aliasDraft = store.aliases[d.name] ?? ""
        editingApp = d
    }

    private func saveAlias() {
        guard let d = editingApp else { return }
        let value = aliasDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            store.aliases.removeValue(forKey: d.name)
        } else {
            store.aliases[d.name] = value
        }
        editingApp = nil
    }
}

// MARK: - 跳转地址编辑器

private struct URLTemplateEditor: View {
    let appName: String
    let defaultTemplate: String
    let copiesToClipboard: Bool
    let onSave: (String) -> Void

    @State private var draft: String
    @State private var lastSample: String?
    @Environment(\.dismiss) private var dismiss

    init(appName: String, template: String, defaultTemplate: String,
         copiesToClipboard: Bool = false,
         onSave: @escaping (String) -> Void) {
        self.appName = appName
        self.defaultTemplate = defaultTemplate
        self.copiesToClipboard = copiesToClipboard
        self.onSave = onSave
        self._draft = State(initialValue: template)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("用 {q} 代表关键词；留空或恢复默认会清掉自定义。")
                    .font(Theme.mono(12))
                    .foregroundColor(Theme.faded)

                if defaultTemplate.contains("{q}") && !draft.contains("{q}") {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11))
                        Text("模板里没有 {q}，关键词带不进去——搜索时只会打开 App，关键词会退回复制到剪贴板。")
                            .font(Theme.mono(11))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(Theme.danger)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.card))
                }

                if copiesToClipboard {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 11))
                        Text("这个应用会先把关键词复制到剪贴板，再打开 App；进去后长按输入框粘贴。")
                            .font(Theme.mono(11))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(Theme.ink)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.card))
                }

                TextEditor(text: $draft)
                    .font(Theme.mono(14))
                    .foregroundColor(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.card))
                    .frame(minHeight: 180)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if let lastSample {
                    Text("测试内容：\(lastSample)")
                        .font(Theme.mono(12))
                        .foregroundColor(Theme.faded)
                }

                HStack {
                    Button("恢复默认") { draft = defaultTemplate }
                        .font(Theme.mono(13))
                        .foregroundColor(Theme.ink)

                    Button("测试") { testURL() }
                        .font(Theme.mono(13))
                        .foregroundColor(Theme.ink)

                    Spacer()

                    Button("取消") { dismiss() }
                        .font(Theme.mono(13))
                        .foregroundColor(Theme.faded)

                    Button("保存") { onSave(draft) }
                        .font(Theme.mono(13, bold: true))
                        .foregroundColor(Theme.paper)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                }
            }
            .padding(20)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("\(appName) 的跳转地址")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func testURL() {
        let samples = [
            "今天天气怎么样？",
            "附近有什么好吃的",
            "推荐一部电影",
            "明天会下雨吗",
            "帮我写一句文案"
        ]
        let sample = samples.randomElement() ?? "今天天气怎么样？"
        lastSample = sample

        let urlString = draft.replacingOccurrences(of: "{q}", with: encodeQuery(sample))
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
