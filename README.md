# ![icon](magickeyboard.png) MagicKeyboard

MagicKeyboard is a library for seamlessly managing the position of text inputs during iOS keyboard appearance. It automatically positions `UITextField`/`UITextViews` so they are visible when the keyboard appears. No Code Required!

## Installation

Add MagicKeyboard to your project using Swift Package Manager. In your Xcode project, select `File` > `Swift Packages` > `Add Package Dependency` and enter the repository URL.

## Basic Usage

MagicKeyboard is a codeless solution to positioning input views when the keyboard appears. All you need to do is instantiate an instance of `MagicKeyboard` that will live for the lifetime of the application.

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    let magicKeyboard = MagicKeyboard()

    ...
}
```

That is all that's needed! MagicKeyboard will handle positioning input views inside a regular `UIView` or `UIScrollView` when the keyboard appears.

## License

MagicKeyboard is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
