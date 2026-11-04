import WidgetKit
import SwiftUI
import Foundation

// MARK: - Timeline

struct MindSearchEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedData.Snapshot
}

struct MindSearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> MindSearchEntry {
        MindSearchEntry(date: Date(), snapshot: SharedData.snapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (MindSearchEntry) -> Void) {
        completion(MindSearchEntry(date: Date(), snapshot: SharedData.snapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MindSearchEntry>) -> Void) {
        let entry = MindSearchEntry(date: Date(), snapshot: SharedData.snapshot())
        // 数据由主 App 主动 WidgetCenter.reloadAllTimelines() 刷新；
        // 这里留 30 分钟兜底，Widget 自己不常驻刷新。
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

/// 所有 deep link 都保证有值，避免视图里散落强制解包
private enum WidgetLinks {
    static let fallback = URL(string: "mindsearch://search")!

    static func search(app: String, keyword: String = "") -> URL {
        SharedData.searchURL(app: app, keyword: keyword) ?? fallback
    }

    static func compose(app: String? = nil) -> URL {
        SharedData.composeURL(app: app) ?? fallback
    }
}

// MARK: - Widget 声明

@main
struct MindSearchWidgetBundle: WidgetBundle {
    var body: some Widget {
        MindSearchHomeWidget()
        MindSearchLockScreenWidget()
    }
}

// MARK: - 主屏小组件（小 / 中 / 大）

struct MindSearchHomeWidget: Widget {
    let kind = "MindSearchHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MindSearchProvider()) { entry in
            HomeWidgetView(entry: entry)
                .modifier(WidgetContainerBackground())
        }
        .configurationDisplayName("MindSearch 快速搜索")
        .description("点常用应用，一键跳到它的搜索结果；点空白处直接打开主 App 输入。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MindSearchEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallHomeView(entry: entry)
            case .systemMedium: MediumHomeView(entry: entry)
            case .systemLarge: LargeHomeView(entry: entry)
            default: MediumHomeView(entry: entry)
            }
        }
    }
}

// MARK: 小尺寸：2×2 应用 + 底部提示

private struct SmallHomeView: View {
    let entry: MindSearchEntry

    var body: some View {
        let apps = Array(entry.snapshot.apps.prefix(4))
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .bold))
                Text("MindSearch")
                    .font(WidgetPalette.mono(11, bold: true))
                Spacer(minLength: 0)
            }
            .foregroundColor(WidgetPalette.ink)
            .padding(.bottom, 8)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                                GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(apps) { app in
                    AppTile(app: app, compact: true)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .font(.system(size: 9))
                Text("点空白处去输入")
                    .font(WidgetPalette.mono(9))
                Spacer(minLength: 0)
            }
            .foregroundColor(WidgetPalette.faded)
        }
        .padding(14)
        .widgetURL(WidgetLinks.compose())
    }
}

// MARK: 中尺寸：左列一句话 + 右列 2×2 应用

private struct MediumHomeView: View {
    let entry: MindSearchEntry

    var body: some View {
        let apps = Array(entry.snapshot.apps.prefix(4))
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .bold))
                    Text("MindSearch")
                        .font(WidgetPalette.mono(11, bold: true))
                    Spacer(minLength: 0)
                }
                .foregroundColor(WidgetPalette.ink)

                Spacer(minLength: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text("用")
                        .font(WidgetPalette.serif(20))
                        .foregroundColor(WidgetPalette.ink)
                    + Text("（app）")
                        .font(WidgetPalette.serif(20))
                        .foregroundColor(WidgetPalette.faded)

                    Text("搜索")
                        .font(WidgetPalette.serif(20))
                        .foregroundColor(WidgetPalette.ink)
                    + Text("（词）")
                        .font(WidgetPalette.serif(20))
                        .foregroundColor(WidgetPalette.faded)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 10))
                    Text("去输入")
                        .font(WidgetPalette.mono(10))
                }
                .foregroundColor(WidgetPalette.paper)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(WidgetPalette.ink))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                                GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(apps) { app in
                    AppTile(app: app, compact: false)
                }
            }
            .frame(width: 150)
        }
        .padding(14)
        .widgetURL(WidgetLinks.compose())
    }
}

// MARK: 大尺寸：4 个应用 + 最近一条搜索（可一键重搜）

private struct LargeHomeView: View {
    let entry: MindSearchEntry

    var body: some View {
        let snap = entry.snapshot
        let apps = Array(snap.apps.prefix(4))
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .bold))
                Text("MindSearch")
                    .font(WidgetPalette.mono(13, bold: true))
                Spacer(minLength: 0)
                Text("点空白处去输入")
                    .font(WidgetPalette.mono(10))
                    .foregroundColor(WidgetPalette.faded)
            }
            .foregroundColor(WidgetPalette.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(apps) { app in
                    AppTile(app: app, compact: false)
                }
            }

            if !snap.lastKeyword.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("最近搜过")
                        .font(WidgetPalette.mono(10))
                        .foregroundColor(WidgetPalette.faded)
                    Link(destination: WidgetLinks.search(
                        app: snap.lastAppName.isEmpty ? (apps.first?.name ?? "小红书") : snap.lastAppName,
                        keyword: snap.lastKeyword
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text(snap.lastKeyword)
                                .font(WidgetPalette.mono(13))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(snap.lastAppName.isEmpty
                                 ? (apps.first?.shortName ?? "")
                                 : snap.lastAppName)
                                .font(WidgetPalette.mono(10))
                                .foregroundColor(WidgetPalette.faded)
                                .lineLimit(1)
                        }
                        .foregroundColor(WidgetPalette.ink)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(WidgetPalette.card))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("搜过一次之后，这里会出现「一键重搜」。")
                    .font(WidgetPalette.mono(11))
                    .foregroundColor(WidgetPalette.faded)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .widgetURL(WidgetLinks.compose())
    }
}

// MARK: - 单个应用块
//
// 点击 = 唤起主 App 并带上这个应用名；关键词为空时主 App 自动聚焦关键词框。

private struct AppTile: View {
    let app: WidgetApp
    let compact: Bool

    var body: some View {
        Link(destination: WidgetLinks.search(app: app.name)) {
            VStack(alignment: .leading, spacing: compact ? 3 : 5) {
                Image(systemName: app.symbol)
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                Text(compact ? app.shortName : app.displayName)
                    .font(WidgetPalette.mono(compact ? 11 : 12, bold: true))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(WidgetPalette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, compact ? 9 : 11)
            .padding(.vertical, compact ? 9 : 11)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WidgetPalette.card))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 锁屏小组件（圆形 / 矩形 / 单行）

struct MindSearchLockScreenWidget: Widget {
    let kind = "MindSearchLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MindSearchProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .modifier(WidgetContainerBackground())
        }
        .configurationDisplayName("MindSearch 锁屏")
        .description("锁屏上放一个常用应用，点一下就能跳去搜索。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MindSearchEntry

    private var primary: WidgetApp? { entry.snapshot.apps.first }
    private var keyword: String { entry.snapshot.lastKeyword }
    private var appName: String { primary?.name ?? "小红书" }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                    Text(primary?.shortName ?? "搜索")
                        .font(WidgetPalette.mono(9, bold: true))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(6)
            }
            .widgetURL(WidgetLinks.search(app: appName))

        case .accessoryRectangular:
            Link(destination: WidgetLinks.search(app: appName)) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: primary?.symbol ?? "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                        Text(keyword.isEmpty ? "用 \(primary?.shortName ?? "App") 搜索" : keyword)
                            .font(WidgetPalette.mono(12, bold: true))
                            .lineLimit(1)
                    }
                    HStack(spacing: 4) {
                        Text("MindSearch")
                            .font(WidgetPalette.mono(9))
                        if !keyword.isEmpty, let app = primary {
                            Text("· \(app.shortName)")
                                .font(WidgetPalette.mono(9))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

        case .accessoryInline:
            Text(keyword.isEmpty
                 ? "MindSearch · 用 \(primary?.shortName ?? "App") 搜索"
                 : "\(primary?.shortName ?? "搜索") · \(keyword)")
                .font(WidgetPalette.mono(11))
                .lineLimit(1)
                .widgetURL(WidgetLinks.search(app: appName))

        default:
            EmptyView()
        }
    }
}
