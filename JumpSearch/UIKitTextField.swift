import SwiftUI
import UIKit

// MARK: - 文字度量

enum FieldMetrics {
    /// 单行时为了让文字在固定高度里垂直居中，需要给 textContainer 加的上/下内边距
    static func verticalInset(font: UIFont, minHeight: CGFloat) -> CGFloat {
        max(0, (minHeight - font.lineHeight) / 2)
    }

    /// 让左侧标签和输入框第一行文字对齐
    static func labelTop(fieldFont: UIFont, minHeight: CGFloat, labelFont: UIFont) -> CGFloat {
        verticalInset(font: fieldFont, minHeight: minHeight)
            + (fieldFont.lineHeight - labelFont.lineHeight) / 2
    }
}

// MARK: - 单行输入框

/// 单行输入框：用 UITextField 而不是 SwiftUI TextField，
/// 第三方输入法（微信、搜狗等）组词时不会被 SwiftUI 的重绘打断。
struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var isComposing: Bool
    let placeholder: String
    let font: UIFont
    let returnKey: UIReturnKeyType
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.font = font
        field.textColor = Theme.inkUIColor
        field.tintColor = Theme.accentUIColor
        field.returnKeyType = returnKey
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.editingChanged(_:)),
                        for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self

        if field.font != font {
            field.font = font
        }

        // 输入法组词期间不要改 text，否则候选会被吞掉
        if field.markedTextRange == nil, field.text != text {
            field.text = text
        }

        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: font,
                .foregroundColor: Theme.placeholderUIColor
            ]
        )

        if isFocused, !field.isFirstResponder {
            field.becomeFirstResponder()
        } else if !isFocused, field.isFirstResponder {
            field.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField

        init(_ parent: UIKitTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
            updateComposing(field)
        }

        func textFieldDidChangeSelection(_ field: UITextField) {
            let text = field.text ?? ""
            let composing = field.markedTextRange != nil
            DispatchQueue.main.async {
                if self.parent.text != text { self.parent.text = text }
                if self.parent.isComposing != composing { self.parent.isComposing = composing }
            }
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            guard !parent.isFocused else { return }
            DispatchQueue.main.async { self.parent.isFocused = true }
        }

        func textFieldDidEndEditing(_ field: UITextField) {
            if parent.isComposing { parent.isComposing = false }
            guard parent.isFocused else { return }
            DispatchQueue.main.async { self.parent.isFocused = false }
        }

        private func updateComposing(_ field: UITextField) {
            let composing = field.markedTextRange != nil
            if parent.isComposing != composing {
                parent.isComposing = composing
            }
        }
    }
}

// MARK: - 自增高输入框

/// 自带高度上报的多行 UITextView。
/// 1 行时是 42pt，随内容长到 maxHeight 封顶，再长就在框内滚动。
final class AutoGrowTextView: UITextView {
    let placeholderLabel = UILabel()

    var minHeight: CGFloat = 42
    var maxHeight: CGFloat = 108
    var onHeightChange: ((CGFloat) -> Void)?

    private var lastReported: CGFloat = 0
    private var lastWidth: CGFloat = 0

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        placeholderLabel.numberOfLines = 1
        placeholderLabel.backgroundColor = .clear
        addSubview(placeholderLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        placeholderLabel.frame = CGRect(x: 0,
                                        y: textContainerInset.top,
                                        width: bounds.width,
                                        height: font?.lineHeight ?? 20)

        // 宽度变了才重新量，避免自己触发自己的布局循环
        if abs(bounds.width - lastWidth) > 0.5 {
            lastWidth = bounds.width
            refreshMetrics()
        }
    }

    /// 内容或字体变化后重新量高度，并把结果报给 SwiftUI
    func refreshMetrics() {
        guard bounds.width > 0 else { return }

        layoutManager.ensureLayout(for: textContainer)
        let used = layoutManager.usedRect(for: textContainer).height
            + textContainerInset.top + textContainerInset.bottom
        let clamped = min(maxHeight, max(minHeight, ceil(used)))
        let needsScroll = used > maxHeight + 0.5

        if isScrollEnabled != needsScroll { isScrollEnabled = needsScroll }
        placeholderLabel.isHidden = !text.isEmpty

        if abs(clamped - lastReported) > 0.5 {
            lastReported = clamped
            onHeightChange?(clamped)
        }
    }
}

/// 多行关键词框：换行键直接提交，不插入换行符。
struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var isComposing: Bool
    @Binding var height: CGFloat
    let placeholder: String
    let font: UIFont
    let minHeight: CGFloat
    let maxHeight: CGFloat
    var lineSpacing: CGFloat = 0
    let onSubmit: () -> Void

    private var verticalInset: CGFloat {
        FieldMetrics.verticalInset(font: font, minHeight: minHeight)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> AutoGrowTextView {
        let view = AutoGrowTextView()
        view.delegate = context.coordinator
        view.font = font
        view.textColor = Theme.inkUIColor
        view.tintColor = Theme.accentUIColor
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.spellCheckingType = .no
        view.returnKeyType = .search
        view.textContainerInset = UIEdgeInsets(top: verticalInset, left: 0,
                                               bottom: verticalInset, right: 0)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        view.minHeight = minHeight
        view.maxHeight = maxHeight
        view.placeholderLabel.font = font
        view.placeholderLabel.textColor = Theme.placeholderUIColor
        view.placeholderLabel.text = placeholder

        view.onHeightChange = { value in
            // 布局期间不能直接改 SwiftUI 状态
            DispatchQueue.main.async {
                if abs(context.coordinator.parent.height - value) > 0.5 {
                    context.coordinator.parent.height = value
                }
            }
        }

        applyTypingAttributes(to: view)
        return view
    }

    func updateUIView(_ view: AutoGrowTextView, context: Context) {
        context.coordinator.parent = self

        if view.font != font {
            view.font = font
            view.placeholderLabel.font = font
        }
        if view.minHeight != minHeight { view.minHeight = minHeight }
        if view.maxHeight != maxHeight { view.maxHeight = maxHeight }

        let inset = UIEdgeInsets(top: verticalInset, left: 0,
                                 bottom: verticalInset, right: 0)
        if view.textContainerInset != inset { view.textContainerInset = inset }

        view.placeholderLabel.text = placeholder

        // 输入法组词期间不要改 text，否则候选会被吞掉
        if view.markedTextRange == nil, view.text != text {
            view.attributedText = attributed(text)
            applyTypingAttributes(to: view)
        }

        view.refreshMetrics()

        if isFocused, !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused, view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    private func applyTypingAttributes(to view: UITextView) {
        view.typingAttributes = [
            .font: font,
            .foregroundColor: Theme.inkUIColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    private var paragraphStyle: NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        return paragraph
    }

    /// 程序写入的文字也要带上字体和行距，否则和显示态对不上
    private func attributed(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: font,
            .foregroundColor: Theme.inkUIColor,
            .paragraphStyle: paragraphStyle
        ])
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView

        init(_ parent: GrowingTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ view: UITextView) {
            parent.text = view.text
            updateComposing(view)
            (view as? AutoGrowTextView)?.refreshMetrics()
        }

        func textViewDidChangeSelection(_ view: UITextView) {
            updateComposing(view)
        }

        /// 换行键 = 提交；组字期间吞掉，不把半截拼音存下来
        func textView(_ view: UITextView,
                      shouldChangeTextIn range: NSRange,
                      replacementText text: String) -> Bool {
            guard text == "\n" else { return true }
            if view.markedTextRange == nil { parent.onSubmit() }
            return false
        }

        func textViewDidBeginEditing(_ view: UITextView) {
            guard !parent.isFocused else { return }
            DispatchQueue.main.async { self.parent.isFocused = true }
        }

        func textViewDidEndEditing(_ view: UITextView) {
            if parent.isComposing { parent.isComposing = false }
            guard parent.isFocused else { return }
            DispatchQueue.main.async { self.parent.isFocused = false }
        }

        private func updateComposing(_ view: UITextView) {
            let composing = view.markedTextRange != nil
            if parent.isComposing != composing {
                parent.isComposing = composing
            }
        }
    }
}
