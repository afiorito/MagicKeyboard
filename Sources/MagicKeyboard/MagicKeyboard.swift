import Combine
import UIKit

/// An object that seamlessly manages the appearance/disappearance of the iOS keyboard.
/// Automatically positions UITextField/UITextViews so they are visible when the keyboard appears.
public class MagicKeyboard: NSObject {
    /// Resign behaviors when tapping outside the responding text input.
    public enum ResignBehaviour {
        /// Always resign when tapping outside the responding text input.
        case always

        /// Resign when the view tapped outside the responding text input is not a subclass of `UIControl`.
        case ignoreControls

        /// Never resign when tapping outside the responding text input.
        case never
    }

    /// A Boolean that determines the resign behaviour when tapping outside the responding text input.
    public var resignsFirstResponderOnTapOutside: ResignBehaviour = .always {
        didSet {
            if resignsFirstResponderOnTapOutside == .never {
                resignFirstResponderGesture.isEnabled = false
            } else {
                resignFirstResponderGesture.isEnabled = true
            }
        }
    }

    /// A collection of view controllers to ignore when making adjustments.
    public var ignoredContainerClasses = [UIViewController.Type]()

    override public init() {
        super.init()
        registerNotifications()
    }

    /// Adjusts the position of an input (UITextField/UITextView) so that it is not covered by the keyboard.
    ///
    /// The movement is handled differently depending on the superview of the input being edited.
    /// When the superview is a scrollview, the input position is adjusted using the `contentOffset` of the scrollview.
    /// Otherwise, the frame of the containing view controller is adjusted.
    private func adjustPosition() {
        guard isEnabled,
              let inputView = inputView, let keyboardFrame = state.keyboardFrame, let window = keyWindow,
              let containerViewController = inputView.containerViewController(excluding: ignoredContainerClasses),
              let containerView = containerViewController.view,
              let containerFrameInWindow = containerView.superview?.convert(
                  state.start.containerOrigin ?? containerView.frame.origin,
                  to: window
              ),
              let inputFrameInWindow = inputView.superview?.convert(inputView.frame, to: window)
        else { return }

        // The visible rect is the area between the top of the keyboard & the top of the containing view controller.
        let topInset: CGFloat = max(containerFrameInWindow.y, containerView.safeAreaInsets.top)
        let height = window.frame.height - keyboardFrame.height - topInset
        let visibleRect = CGRect(x: 0, y: topInset, width: window.frame.width, height: height)
        let fitsInVisibleRect = inputFrameInWindow.height <= visibleRect.height

        // Input is completely visible. No need to adjust.
        guard inputFrameInWindow.maxY > visibleRect.maxY || inputFrameInWindow.minY < visibleRect.minY else { return }

        // If the input fully fits above the keyboard align the bottom of the input to the keyboard.
        // Otherwise, align the input to the top of the visible rect.
        var move = fitsInVisibleRect ? keyboardFrame.minY - inputFrameInWindow.maxY : visibleRect
            .midY - inputFrameInWindow.minY

        if let superScrollView = inputView.superviewOfType(UIScrollView.self, below: containerView),
           let scrollViewFrameInWindow = superScrollView.superview?.convert(superScrollView.frame, to: window)
        {
            if !fitsInVisibleRect, let textInput = inputView as? UITextInput,
               let textPosition = textInput.selectedTextRange?.start
            {
                let caretRect = inputView.convert(textInput.caretRect(for: textPosition), to: window)
                move = caretRect.maxY > visibleRect.height ? keyboardFrame.minY - caretRect.maxY : .zero
            }

            state.start.scrollViewContentInsetAdjustmentBehavior ??= superScrollView.contentInsetAdjustmentBehavior
            state.start.scrollViewContentInset ??= superScrollView.contentInset
            state.start.scrollViewContentOffset ??= superScrollView.contentOffset
            state.start.scrollViewVerticalScrollIndicatorInset ??= superScrollView.verticalScrollIndicatorInsets

            let newContentOffset = CGPoint(
                x: superScrollView.contentOffset.x,
                y: max(.zero, superScrollView.contentOffset.y - move)
            )

            animateAlongsideKeyboard {
                self.updateBottomInset(scrollViewFrameInWindow.maxY - keyboardFrame.minY, for: superScrollView)
                superScrollView.setContentOffset(newContentOffset, animated: true)
            }

        } else {
            let navigationController = containerViewController.navigationController
            state.start.navigationBarAppearance = navigationController?.navigationBar.scrollEdgeAppearance

            if let appearance = navigationController?.navigationBar.standardAppearance {
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
            }

            state.start.containerOrigin ??= containerView.frame.origin

            animateAlongsideKeyboard {
                containerView.frame.origin.y = min(.zero, containerView.frame.origin.y + move)
            }

            if !fitsInVisibleRect, let inputScrollView = inputView as? UIScrollView {
                state.start.inputContentInsetAdjustmentBehavior ??= inputScrollView.contentInsetAdjustmentBehavior
                state.start.inputContentInset ??= inputScrollView.contentInset
                state.start.inputVerticalScrollIndicatorInset ??= inputScrollView.verticalScrollIndicatorInsets

                animateAlongsideKeyboard {
                    self.updateBottomInset(
                        inputFrameInWindow.maxY + min(.zero, move) - keyboardFrame.minY,
                        for: inputScrollView
                    )
                }
            }
        }
    }

    private func adjustPositionIfNeeded() {
        if !state.isAdjusting {
            state.isAdjusting = true
            OperationQueue.main.addOperation {
                self.adjustPosition()
                self.state.isAdjusting = false
            }
        }
    }

    /// Resets the position of an input (UITextField/UITextView)
    /// so that it returns to the position it was before the keyboard appeared.
    ///
    /// Reverses the adjustments made by calling `adjustPosition`.
    private func resetPosition(ignoringSuperView: Bool = false) {
        guard isEnabled,
              let inputView = inputView,
              let containerViewController = inputView.containerViewController(excluding: ignoredContainerClasses)
        else { return }

        containerViewController.additionalSafeAreaInsets = .zero

        animateAlongsideKeyboard {
            if !ignoringSuperView, let superScrollView = inputView.superviewOfType(
                UIScrollView.self,
                below: containerViewController.view
            ) {
                superScrollView.contentInsetAdjustmentBehavior =?? self.state.start
                    .scrollViewContentInsetAdjustmentBehavior
                superScrollView.contentOffset =?? self.state.start.scrollViewContentOffset
                superScrollView.contentInset =?? self.state.start.scrollViewContentInset
                superScrollView.verticalScrollIndicatorInsets =?? self.state.start
                    .scrollViewVerticalScrollIndicatorInset
            } else {
                if let appearance = self.state.start.navigationBarAppearance {
                    containerViewController.navigationController?.navigationBar.scrollEdgeAppearance = appearance
                }

                containerViewController.view.frame.origin =?? self.state.start.containerOrigin
            }

            if let inputScrollView = inputView as? UIScrollView {
                inputScrollView.contentInsetAdjustmentBehavior =?? self.state.start.inputContentInsetAdjustmentBehavior
                inputScrollView.contentInset =?? self.state.start.inputContentInset
                inputScrollView.verticalScrollIndicatorInsets =?? self.state.start.inputVerticalScrollIndicatorInset
            }
        }
    }

    // MARK: - Input Editing Events

    /// Handle an input end editing event.
    ///
    ///  - Parameters:
    ///     - event: The input editing event to be handled.
    ///
    /// All access to inputView needs to happen after this event since it's not guaranteed that
    /// `keyboardWillShow` is called after `didBeginEditing`. For UITextFields, this event
    /// happens before `keyboardWillShow`. However for UITextViews, this event happens after
    /// `keyboardWillShow`.
    private func inputDidBeginEditing(_ event: InputEditingEvent) {
        resetPosition(ignoringSuperView: true)

        inputView = event.inputView
        inputView?.window?.addGestureRecognizer(resignFirstResponderGesture)

        adjustPositionIfNeeded()
    }

    /// Handle an input end editing event.
    ///
    ///  - Parameters:
    ///     - event: The input editing event to be handled.
    private func inputDidEndEditing(_ event: InputEditingEvent) {
        inputView?.window?.removeGestureRecognizer(resignFirstResponderGesture)
    }

    // MARK: - Keyboard Events

    /// Handle a keyboard will show event.
    ///
    /// - Parameters:
    ///     - event: The keyboard event to be handled.
    ///
    /// All access to the `keyboardFrame` needs to happen after this event.
    private func keyboardWillShow(_ event: KeyboardEvent) {
        guard state.position == .start else { return }

        state.keyboardFrame = event.endFrame
        state.animationDuration = event.animationDuration ?? state.animationDuration
        state.animationCurve = event.animationCurve ?? state.animationCurve

        adjustPositionIfNeeded()
    }

    /// Handle a keyboard did show event.
    ///
    /// - Parameters:
    ///     - event: The keyboard event to be handled.
    ///
    /// After this event, the keyboard is at its end position.
    private func keyboardDidShow(_ event: KeyboardEvent) {
        state.position = .end
    }

    /// Handle a keyboard will hide event.
    ///
    /// - Parameters:
    ///     - event: The keyboard event to be handled.
    ///
    /// This event signals that the keyboard is disappearing, so reset the adjustments.
    private func keyboardWillHide(_ event: KeyboardEvent) {
        resetPosition()
        inputView?.responderViewController?.view.setNeedsLayout()
    }

    /// Handle a keyboard did hide event.
    ///
    /// - Parameters:
    ///     - event: The keyboard event to be handled.
    ///
    /// After this event, the keyboard is hidden. Reset the state for the next appearance.
    private func keyboardDidHide(_ event: KeyboardEvent) {
        state = KeyboardState()
    }

    // MARK: - Orientation Events

    private func orientationDidChange(_ event: OrientationChangeEvent) {
        guard event.orientation != .unknown, state.orientation != event.orientation else { return }

        state.orientation = event.orientation ?? UIDevice.current.orientation
        resetPosition()
    }

    // MARK: - Helpers

    private func registerNotifications() {
        // keyboard notifications
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map(KeyboardEvent.map).sink(receiveValue: keyboardWillShow).store(in: &notifications)
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .map(KeyboardEvent.map).sink(receiveValue: keyboardDidShow).store(in: &notifications)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map(KeyboardEvent.map).sink(receiveValue: keyboardWillHide).store(in: &notifications)
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .map(KeyboardEvent.map).sink(receiveValue: keyboardDidHide).store(in: &notifications)

        // text input view notifications
        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)
            .map(InputEditingEvent.map).sink(receiveValue: inputDidBeginEditing).store(in: &notifications)
        NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)
            .map(InputEditingEvent.map).sink(receiveValue: inputDidEndEditing).store(in: &notifications)
        NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)
            .map(InputEditingEvent.map).sink(receiveValue: inputDidBeginEditing).store(in: &notifications)
        NotificationCenter.default.publisher(for: UITextView.textDidEndEditingNotification)
            .map(InputEditingEvent.map).sink(receiveValue: inputDidEndEditing).store(in: &notifications)

        // orientation notifications
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .map(OrientationChangeEvent.map).sink(receiveValue: orientationDidChange).store(in: &notifications)
    }

    private func animateAlongsideKeyboard(animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: state.animationDuration, delay: 0,
                       options: state.animationCurve.union(.beginFromCurrentState),
                       animations: animations, completion: completion)
    }

    private func updateBottomInset(_ inset: CGFloat, for scrollView: UIScrollView) {
        let safeAreaInsets = scrollView.safeAreaInsets

        scrollView.contentInset.bottom = max(scrollView.contentInset.bottom, inset)
        scrollView.verticalScrollIndicatorInsets.bottom = max(
            scrollView.verticalScrollIndicatorInsets.bottom,
            inset - safeAreaInsets.bottom
        )
        scrollView.contentInset.top = safeAreaInsets.top
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    // MARK: - Properties

    private weak var inputView: UIView?
    private var notifications = Set<AnyCancellable>()
    private var state = KeyboardState()

    private var isEnabled: Bool {
        guard let inputView = inputView else { return false }
        return !disabledContainerClasses.contains(where: { inputView.responderViewController?.isKind(of: $0) == true })
    }

    private var disabledContainerClasses: [UIViewController.Type] = [
        UITableViewController.self,
        UIAlertController.self,
    ]

    private var keyWindow: UIWindow? {
        inputView?.window ?? UIApplication.shared.windows.filter(\.isKeyWindow).first
    }

    // MARK: - Resign Gesture Recognizer

    private lazy var resignFirstResponderGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleResignFirstResponder))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        return tapGesture
    }()

    @objc private func handleResignFirstResponder(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            resignFirstResponder()
        }
    }

    @discardableResult
    private func resignFirstResponder() -> Bool {
        inputView?.resignFirstResponder() ?? false
    }
}

// MARK: - UIGestureRecognizer Delegate

extension MagicKeyboard: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if resignsFirstResponderOnTapOutside == .ignoreControls, touch.view is UIControl {
            return false
        }
        return true
    }
}

/// Set an optional instance to itself or a value if nil.
///
/// Using this operator is equivalent to:
///
///     var value: Int = 5
///     var optionalValue: Int?
///
///     optionalValue = optionalValue ?? value
///
/// - Parameters:
///     - optional: An optional value.
///     - value: A value to use if the optional is nil. The value is the same type as the wrapped type of the optional.
infix operator ??=
func ??= <T>(optional: inout T?, value: @autoclosure () -> T) {
    optional = optional ?? value()
}

/// Set a value to an optional instance or to itself.
///
/// Using this operator is equivalent to:
///
///     var value: Int = 5
///     var optionalValue: Int?
///
///     value = optionalValue ?? value
///
/// - Parameters:
///     - optional: An optional value.
///     - value: A value to use if the optional is nil. The value is the same type as the wrapped type of the optional.
infix operator =??
func =?? <T>(left: inout T, right: inout T?) {
    left = right ?? left
}
