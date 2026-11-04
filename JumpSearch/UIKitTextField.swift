import SwiftUI
import UIKit

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
    var onHoldStart: (() -> Void)? = nil   // 按住开始
    var onHoldEnd: (() -> Void)? = nil     // 松手结束

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.font = font
        field.textColor = UIColor(Theme.ink)
        field.tintColor = UIColor(Theme.ink)
        field.returnKeyType = returnKey
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.editingChanged(_:)),
                        for: .editingChanged)

        if onHoldStart != nil || onHoldEnd != nil {
            let hold = UILongPressGestureRecognizer(target: context.coordinator,
                                                    action: #selector(Coordinator.handleHold(_:)))
            hold.minimumPressDuration = 0.4
            hold.cancelsTouchesInView = true
            hold.allowableMovement = 12
            field.addGestureRecognizer(hold)
        }

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
                .foregroundColor: UIColor(Theme.ink.opacity(0.28))
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

        @objc func handleHold(_ g: UILongPressGestureRecognizer) {
            switch g.state {
            case .began:
                parent.onHoldStart?()
            case .ended, .cancelled, .failed:
                parent.onHoldEnd?()
            default:
                break
            }
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
