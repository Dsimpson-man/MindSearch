import SwiftUI

/// 首次打开的三页引导：一句话搜索、首字母识别、长文本存想法。
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @State private var appeared = false

    private struct Page {
        let title: String
        let body: String
        let hint: String
    }

    private let pages: [Page] = [
        Page(title: "用一句话\n去任何地方",
             body: "选一个应用，写下想搜的，回车就走。",
             hint: "用（小红书）搜索（露营装备）"),
        Page(title: "输入 XH\n就是小红书",
             body: "汉字、拼音、首字母、别名，都能认出来。",
             hint: "xhs · xy · wb · dy · tb"),
        Page(title: "长一点的想法\n会留下来",
             body: "超过 20 字回车，存进「想法」；搜过的都在「记录」。",
             hint: "想搜什么，先写下来")
    ]

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                ZStack(alignment: .leading) {
                    ForEach(pages.indices, id: \.self) { index in
                        if index == page {
                            content(pages[index])
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)

                Spacer(minLength: 0)

                HStack(spacing: 9) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == page ? Theme.accent : Theme.ink.opacity(0.14))
                            .frame(width: index == page ? 7 : 5,
                                   height: index == page ? 7 : 5)
                    }

                    Spacer(minLength: 0)

                    Button(action: advance) {
                        Text(page == pages.count - 1 ? "开始" : "继续")
                            .font(Theme.mono(13, bold: true))
                            .foregroundColor(Theme.paper)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Theme.accent))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(page == pages.count - 1 ? "开始使用" : "下一页")
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 46)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
        }
        .animation(.easeInOut(duration: 0.55), value: page)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { appeared = true }
        }
    }

    private func content(_ item: Page) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(item.title)
                .font(Theme.serif(34))
                .foregroundColor(Theme.ink)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.body)
                .font(Theme.mono(13))
                .foregroundColor(Theme.faded)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.hint)
                .font(Theme.serif(17))
                .foregroundColor(Theme.accent)
                .padding(.top, 4)
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.55)) { page += 1 }
        } else {
            onFinish()
        }
    }
}
