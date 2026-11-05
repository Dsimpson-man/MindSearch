import SwiftUI
import UIKit

/// 水墨玻璃背景：暖纸底 + 四团墨晕 + 六套可切换的背景线 + 颗粒 + 压角。
///
/// 坐标系统一是 390 × 844（和设计稿一致），按屏幕宽度整体缩放。
/// `parallax` 是压缩后的滚动量：远层 0.12、中层 0.26、近层 0.46。
struct InkBackground: View {
    var theme: InkLineTheme = .ridge
    var parallax: CGFloat = 0
    var emphasis: Double = 0

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var dark: Bool { scheme == .dark }

    private static let artSize = CGSize(width: 390, height: 844)

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.artSize.width
            let height = max(geo.size.height, Self.artSize.height * scale)

            ZStack(alignment: .topLeading) {
                paper

                art
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: Self.artSize.width * scale,
                           height: height,
                           alignment: .topLeading)

                grain
                    .opacity(dark ? 0.05 : 0.14)
                    .blendMode(dark ? .screen : .multiply)

                vignette
            }
            .frame(width: geo.size.width, height: height, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
    }

    // MARK: - 纸

    private var paper: some View {
        LinearGradient(
            colors: dark
                ? [Color(red: 0.082, green: 0.082, blue: 0.090),
                   Color(red: 0.098, green: 0.098, blue: 0.106),
                   Color(red: 0.118, green: 0.116, blue: 0.122)]
                : [Color(red: 0.984, green: 0.976, blue: 0.953),
                   Color(red: 0.957, green: 0.945, blue: 0.910),
                   Color(red: 0.922, green: 0.902, blue: 0.855)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - 画面本身（墨晕 + 线）

    private var art: some View {
        ZStack(alignment: .topLeading) {
            washes
            lines
        }
        .frame(width: Self.artSize.width, height: Self.artSize.height,
               alignment: .topLeading)
    }

    private var washes: some View {
        ZStack(alignment: .topLeading) {
            wash(width: 820, height: 560, x: -340, y: -260, rotation: -16,
                 color: inkWash(0.26, warm: true),
                 core: 0.40, ring: (0.58, 0.68, 0.78), ringAlpha: 0.075)

            wash(width: 700, height: 460, x: -10, y: 330, rotation: 14,
                 color: inkWash(0.22, warm: false),
                 core: 0.42, ring: (0.56, 0.68, 0.79), ringAlpha: 0.065)

            wash(width: 760, height: 620, x: -320, y: 544, rotation: -8,
                 color: inkWash(0.20, warm: true),
                 core: 0.42, ring: (0.58, 0.70, 0.80), ringAlpha: 0.06)

            wash(width: 540, height: 420, x: 40, y: 464, rotation: -6,
                 color: inkWash(0.11, warm: false),
                 core: 0.48, ring: nil, ringAlpha: 0)

            // 一道横过纸面的飞白笔触
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [inkWash(0.085, warm: true), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 190
                    )
                )
                .frame(width: 520, height: 210)
                .blur(radius: 10)
                .rotationEffect(.degrees(-9))
                .offset(x: -60, y: 300)
                .opacity(0.9)
        }
    }

    /// 一团墨晕：中间淡，外面留一圈“水线”
    private func wash(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat,
                      rotation: Double, color: Color, core: CGFloat,
                      ring: (CGFloat, CGFloat, CGFloat)?, ringAlpha: Double) -> some View {
        let diameter = max(width, height)
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: color, location: 0),
                            .init(color: color.opacity(0.28), location: core),
                            .init(color: color.opacity(0), location: 0.80)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.5
                    )
                )

            if let ring {
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: color.opacity(0), location: 0),
                                .init(color: color.opacity(ringAlpha * 3), location: ring.1),
                                .init(color: color.opacity(0), location: ring.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: diameter * 0.5
                        )
                    )
            }
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(x: width / diameter, y: height / diameter)
        .rotationEffect(.degrees(rotation))
        .position(x: x + width / 2, y: y + height / 2)
    }

    private func inkWash(_ alpha: Double, warm: Bool) -> Color {
        if dark {
            return Color(red: 0.86, green: 0.85, blue: 0.82).opacity(alpha * 0.55)
        }
        return warm
            ? Color(red: 0.11, green: 0.12, blue: 0.13).opacity(alpha)
            : Color(red: 0.18, green: 0.24, blue: 0.29).opacity(alpha)
    }

    // MARK: - 线

    private var lines: some View {
        let data = InkThemeData.of(theme)
        return ZStack(alignment: .topLeading) {
            group(data.far, rate: 0.12)
            group(data.mid, rate: 0.26)
            group(data.near, rate: 0.46)
        }
        .frame(width: Self.artSize.width, height: Self.artSize.height,
               alignment: .topLeading)
    }

    @ViewBuilder
    private func group(_ list: [InkLine], rate: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(list) { line in
                line.path
                    .stroke(
                        LinearGradient(
                            stops: line.stroke.stops(dark: dark),
                            startPoint: line.stroke.isVertical ? .bottom : .leading,
                            endPoint: line.stroke.isVertical ? .top : .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: line.width,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: line.dash
                        )
                    )
                    .opacity(line.opacity)
                    .blur(radius: line.blur)
            }
        }
        .frame(width: Self.artSize.width, height: Self.artSize.height,
               alignment: .topLeading)
        .offset(y: reduceMotion ? 0 : -parallax * rate)
    }

    // MARK: - 压角与颗粒

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, Color.black.opacity(dark ? 0.34 : 0.07)],
            center: UnitPoint(x: 0.5, y: 0.36),
            startRadius: 120,
            endRadius: 520
        )
        .allowsHitTesting(false)
    }

    private var grain: some View {
        Image(uiImage: Self.texture)
            .resizable(resizingMode: .tile)
            .allowsHitTesting(false)
    }

    private static let texture: UIImage = {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            for _ in 0..<620 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let alpha = CGFloat.random(in: 0.008...0.020)
                cg.setFillColor(UIColor(red: 0.18, green: 0.17, blue: 0.15, alpha: alpha).cgColor)
                cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
            for _ in 0..<26 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let width = CGFloat.random(in: 4...15)
                let alpha = CGFloat.random(in: 0.006...0.014)
                cg.setStrokeColor(UIColor(red: 0.18, green: 0.17, blue: 0.15, alpha: alpha).cgColor)
                cg.setLineWidth(0.6)
                cg.move(to: CGPoint(x: x, y: y))
                cg.addLine(to: CGPoint(x: x + width, y: y))
                cg.strokePath()
            }
        }
    }()
}

// MARK: - 玻璃

/// 纸上的磨砂玻璃：底色 + 镜面高光 + 内亮边 + 接触阴影。
/// iOS 26 的 `.ultraThinMaterial` 在浅纸上几乎透明，所以自己叠一层。
struct InkGlass<S: InsettableShape>: ViewModifier {
    var shape: S
    var strong: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(strong ? 0.34 : 0.22), location: 0),
                                .init(color: .white.opacity(strong ? 0.12 : 0.07), location: 0.42),
                                .init(color: .white.opacity(strong ? 0.06 : 0.03), location: 0.68),
                                .init(color: .white.opacity(strong ? 0.20 : 0.12), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay(shape.strokeBorder(Color.white.opacity(0.72), lineWidth: 1))
            .overlay(shape.strokeBorder(Theme.ink.opacity(0.14), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.11), radius: 18, y: 8)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

extension View {
    func inkGlass<S: InsettableShape>(_ shape: S, strong: Bool = false) -> some View {
        modifier(InkGlass(shape: shape, strong: strong))
    }
}

// MARK: - 主题缩略图

/// 设置页里的小样：只画线，不做墨晕，笔触按比例加粗，小尺寸才看得清
struct InkThemePreview: View {
    let theme: InkLineTheme

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / 390, 0.12)
            let data = InkThemeData.of(theme)
            let dark = scheme == .dark

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: dark
                        ? [Color(red: 0.10, green: 0.10, blue: 0.11),
                           Color(red: 0.15, green: 0.148, blue: 0.152)]
                        : [Color(red: 0.984, green: 0.976, blue: 0.953),
                           Color(red: 0.922, green: 0.902, blue: 0.855)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ZStack(alignment: .topLeading) {
                    ForEach(data.far + data.mid + data.near) { line in
                        line.path
                            .stroke(
                                LinearGradient(
                                    stops: line.stroke.stops(dark: dark),
                                    startPoint: line.stroke.isVertical ? .bottom : .leading,
                                    endPoint: line.stroke.isVertical ? .top : .trailing
                                ),
                                style: StrokeStyle(
                                    lineWidth: max(line.width, 1) * 2.2,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .opacity(line.opacity)
                    }
                }
                .frame(width: 390, height: 844, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(y: geo.size.height * 0.5 - 560 * scale)
            }
            .clipped()
        }
    }
}

// MARK: - 滚动量：给背景喂视差

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// 放在 ScrollView 内容顶部，量出滚动距离
    func trackScrollOffset(in space: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollOffsetKey.self,
                    value: -geo.frame(in: .named(space)).minY
                )
            }
        )
    }
}
