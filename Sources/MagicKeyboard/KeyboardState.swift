import UIKit

/// A structure for representing the current state of the keyboard presentation.
struct KeyboardState {
    /// The position of the keyboard.
    enum Position {
        case start
        case end
    }

    /// The starting values before keyboard appearance.
    struct Start {
        var containerSafeAreaInsets: UIEdgeInsets = .zero
        var containerOrigin: CGPoint?

        var inputContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior?
        var inputContentInset: UIEdgeInsets?
        var inputVerticalScrollIndicatorInset: UIEdgeInsets?

        var scrollViewContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior?
        var scrollViewContentInset: UIEdgeInsets?
        var scrollViewVerticalScrollIndicatorInset: UIEdgeInsets?
        var scrollViewContentOffset: CGPoint?
    }

    /// The end frame of the keyboard.
    var keyboardFrame: CGRect?

    /// The animation duration of the keyboard animation.
    var animationDuration: TimeInterval = 0.25

    /// The animation curve of the keyboard animation.
    var animationCurve: UIView.AnimationOptions = .curveEaseOut

    /// The current device orientation.
    var orientation: UIDeviceOrientation = UIDevice.current.orientation

    /// A boolean that determines if inputs are being ajusted.
    var isAdjusting = false

    /// The current position of the keyboard. Default is the starting position.
    var position: Position = .start

    /// The starting values before keyboard appearance.
    var start = Start()
}
