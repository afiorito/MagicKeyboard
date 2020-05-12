import UIKit

/// A structure for representing a keyboard event.
struct KeyboardEvent {
    var animationCurve: UIView.AnimationOptions?
    var animationDuration: TimeInterval?
    var endFrame: CGRect?
    var startFrame: CGRect?
    var isLocal: Bool?

    static func extractAnimationOptions(from notification: Notification) -> UIView.AnimationOptions? {
        if let rawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            return UIView.AnimationOptions(rawValue: rawValue)
        }

        return nil
    }

    static func map(_ notification: Notification) -> Self {
        KeyboardEvent(
            animationCurve: extractAnimationOptions(from: notification),
            animationDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            endFrame: notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            startFrame: notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            isLocal: notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool
        )
    }
}

/// A structure for representing an input editing event.
struct InputEditingEvent {
    var inputView: UIView?

    static func map(_ notification: Notification) -> Self {
        InputEditingEvent(inputView: notification.object as? UIView)
    }
}

/// A structure for representing an orientation event.
struct OrientationChangeEvent {
    var orientation: UIDeviceOrientation?

    static func map(_ notification: Notification) -> Self {
        OrientationChangeEvent(orientation: (notification.object as? UIDevice)?.orientation)
    }
}
