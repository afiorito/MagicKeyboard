import UIKit

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
    func containerViewController(excluding parentViewControllers: [UIViewController.Type] = []) -> UIViewController? {
        let exemptControllers = [UISplitViewController.self] + parentViewControllers

        var container: UIViewController? = responderViewController

        while let parent = container?.parent, !exemptControllers.contains(where: { parent.isKind(of: $0) }) {
            container = parent
        }

        while let child = container {
            if let navController = child as? UINavigationController {
                container = navController.topViewController
            } else if let tabController = child as? UITabBarController {
                container = tabController.selectedViewController
            } else {
                return container
            }
        }

        return container
    }

    /// Returns a superview of the specified type.
    ///
    /// - Parameters:
    ///     - type: The superview type.
    /// - Returns: A superview of the specified type or nil if there is no superview with the specified type.
    func superviewOfType<T>(_ type: T.Type = T.self, below view: UIView? = nil) -> T? {
        var superview = self.superview

        var topSuperView: T?

        while let parent = superview, parent != view {
            if let parent = superview as? T {
                topSuperView = parent
            }

            superview = parent.superview
        }

        return topSuperView
    }
}
