[English](./README.en.md) | [正體中文](./README.md)

# [WWFontLoader](https://swiftpackageindex.com/William-Weng)

iOS 字型載入器 - 支援系統內建字型和外部的 TTF 字型檔案，自動註冊並提供全域 Font 存取。

![WWFontLoader](https://github.com/user-attachments/assets/d40712e5-2625-4958-a2d6-ef479752bcbf)

## ✨ 特性

- 📱 **支援系統內建字型** - 使用 `name` 參數指定 PostScript 名稱
- 📂 **支援外部 TTF 檔案** - 從 Bundle 或 Documents 讀取並動態註冊
- ✅ **自動檢測已註冊** - 避免重複註冊導致錯誤（錯誤碼 305）
- 🎯 **全域 Font 存取** - `FontResolver.shared.english` 直接使用
- 📝 **JSON 配置** - 透過 `FontConfig` 簡化字型設定
- 🛡️ **錯誤處理** - 詳細的 `CustomError` 錯誤訊息

## 📦 安裝

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/William-Weng/WWFontLoader.git", from: "1.0.0")
]
```

## 🛠️ 公開 API

| API (WWSQLite3Manager) | 說明 |
|---|---|
| `loadFont(source:)` | 載入字型。 |
| `postScriptName(from:)` | 從 TTF 檔案讀取 PostScript 名稱。 |
| `checkFontRegistered(postScriptName:)` | 檢查字型是否已註冊。 |

## 🚀 [使用範例](https://peterpanswift.github.io/iphone-bezels/)

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

## ⚠️ 注意事項

### 錯誤碼 305

如果遇到 `CTFontManagerError.alreadyRegistered`（錯誤碼 305），表示字型已註冊。WWFontLoader 會自動檢測並跳過重複註冊。

```swift
// 自動檢測
if loader.checkFontRegistered(postScriptName: "jf-openhuninn") {
    print("⚠️ 字型已註冊")
}
```

### Registring 記憶體管理

使用 `takeUnretainedValue()` 而非 `takeRetainedValue()`，因為 `CTFontManagerRegisterFontsForURL` 是 "Get" 函數，不消耗 retain count。

### TTF 檔案路徑

[TTF 檔案](https://github.com/mcdtaiwan/Chicken_McNuggets)可以從以下位置讀取：

```swift
// Bundle（推薦）
let url = Bundle.main.url(forResource: "font.ttf", withExtension: nil)!

// Documents
let url = URL.documentsDirectory.appendingPathComponent("font.ttf")
```
