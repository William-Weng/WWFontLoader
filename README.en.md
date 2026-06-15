[English](./README.en.md) | [正體中文](./README.md)

# [WWFontLoader](https://swiftpackageindex.com/William-Weng)

An iOS font loader that supports built-in system fonts and external TTF font files, automatically registers them, and provides global Font access.

![WWFontLoader](https://github.com/user-attachments/assets/d40712e5-2625-4958-a2d6-ef479752bcbf)

## ✨ Features

- 📱 **Supports built-in system fonts** - Specify the PostScript name using the `name` parameter.
- 📂 **Supports external TTF files** - Load from Bundle or Documents and register dynamically.
- ✅ **Automatic registration check** - Avoid duplicate registration errors (error code 305).
- 🎯 **Global Font access** - Use `FontResolver.shared.english` directly.
- 📝 **JSON configuration** - Simplify font setup with `FontConfig`.
- 🛡️ **Error handling** - Detailed `CustomError` messages.

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/William-Weng/WWFontLoader.git", from: "1.0.0")
]
```

## 🛠️ Public API

| API (WWFontLoader) | Description |
|---|---|
| `loadFont(source:)` | Loads a font. |
| `postScriptName(from:)` | Reads the PostScript name from a TTF file. |
| `checkFontRegistered(postScriptName:)` | Checks whether the font has already been registered. |

## 🚀 [Example](https://peterpanswift.github.io/iphone-bezels/)

```swift
import UIKit
import WWFontLoader

final class ViewController: UIViewController {

    @IBOutlet weak var ttfLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFont()
    }
    
    func loadFont() {
        
        do {
            let url = Bundle.main.url(forResource: "ChickenMcNuggets.ttf", withExtension: nil)!
            
            ttfLabel.font = try WWFontLoader.shared.loadFont(source: .ttf(url: url, size: 42))
            ttfLabel.text = WWFontLoader.shared.postScriptName(from: url)
            
        } catch {
            print(error)
        }
    }
}
```

## ⚠️ Notes

### Error Code 305

If you encounter `CTFontManagerError.alreadyRegistered` (error code 305), it means the font has already been registered. WWFontLoader automatically detects this and skips duplicate registration.

```swift
// Automatic check
if loader.checkFontRegistered(postScriptName: "jf-openhuninn") {
    print("⚠️ Font is already registered")
}
```

### Registering Memory Management

Use `takeUnretainedValue()` instead of `takeRetainedValue()`, because `CTFontManagerRegisterFontsForURL` is a "Get" function and does not consume the retain count.

### TTF File Paths

[TTF files](https://github.com/mcdtaiwan/Chicken_McNuggets) can be loaded from the following locations:

```swift
// Bundle (recommended)
let url = Bundle.main.url(forResource: "font.ttf", withExtension: nil)!

// Documents
let url = URL.documentsDirectory.appendingPathComponent("font.ttf")
```
