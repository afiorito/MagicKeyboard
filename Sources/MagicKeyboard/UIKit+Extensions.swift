import UIKit

extension UIViewController {
    /// Returns a unique identifier for a UIViewController class or metatype.
    var objectIdentifier: ObjectIdentifier {
        return ObjectIdentifier(type(of: self))
    }

    /// Returns a unique identifier for a UIViewController class instance or metatype
    static var objectIdentifier: ObjectIdentifier {
        return ObjectIdentifier(type(of: Self.self))
    }
}

extension UIView {
    /// Returns the responding view controller of the view or nil if there is no responding view controller.
    var responderViewController: UIViewController? {
        var responder: UIResponder? = self

        while let next = responder {
            if let viewController = next as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }

    /// Returns the view controller containing the view or nil if there is no containing view controller.
    ///
    /// UINavigationController, UITabBarController, UISplitViewController are excluded.
    var containerViewController: UIViewController? {
        let exemptControllers = Set([
            UINavigationController.objectIdentifier,
            UITabBarController.objectIdentifier,
            UISplitViewController.objectIdentifier
        ])

        var container: UIViewController? = responderViewController

        while let parent = container?.parent, !exemptControllers.contains(parent.objectIdentifier) {
            container = parent
        }

        return container
    }

    /// Returns a superview of the specified type.
    ///
    /// - Parameters:
    ///     - type: The superview type.
    /// - Returns: A superview of the specified type or nil if there is no superview with the specified type.
    func superviewOfType<T>(_ type: T.Type = T.self) -> T? {
        var superview = self.superview

        while let view = superview {
            if let view = superview as? T {
                return view
            }

            superview = view.superview
        }

        return nil
    }
}
