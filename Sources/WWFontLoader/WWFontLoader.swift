// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import CoreText

/// 字型載入器
///
/// 負責載入系統內建字型和外部的 TTF 字型檔案，支援動態註冊和錯誤處理
final public class WWFontLoader {
    public static let shared = WWFontLoader()
}

// MARK: - public
public extension WWFontLoader {
    
    /// 載入字型
    ///
    /// 根據字型來源（系統或 TTF）載入對應的 UIFont，如果是 TTF 檔案，會自動註冊到系統字型管理器
    ///
    /// - Parameter source: 字型來源（`system` 或 `ttf`）
    /// - Returns: UIFont 物件
    /// - Throws: `CustomError` 如果載入失敗
    func loadFont(source: FontSource) throws -> UIFont {
        
        switch source {
        case .system(let postScriptName, let size): return try loadSystemFont(name: postScriptName, size: size)
        case .ttf(let url, let size): return try loadTTFFont(url: url, size: size)
        }
    }
    
    /// 從 TTF 檔案讀取 PostScript 名稱
    ///
    /// 從字型檔中提取 PostScript 名稱，用於後續的字型註冊和使用
    ///
    /// - Parameter url: TTF 檔案的 URL
    /// - Returns: PostScript 名稱（如果成功讀取）
    func postScriptName(from url: URL) -> String? {
        
        guard let dataProvider = CGDataProvider(url: url as CFURL),
              let cgFont = CGFont(dataProvider)
        else {
            return nil
        }
        
        guard let postScriptName = cgFont.postScriptName else { return nil }
        return String(postScriptName)
    }
    
    /// 檢查字型是否已註冊
    ///
    /// 使用 `UIFont(name:)` 檢查字型是否已經註冊到系統中，避免重複註冊導致錯誤（錯誤碼 305）。
    func checkFontRegistered(postScriptName: String) -> Bool {
        let font = UIFont(name: postScriptName, size: 12)
        return font != nil
    }
}

// MARK: - private
private extension WWFontLoader {
    
    /// 從 URL 載入 UIFont（內部方法）
    ///
    /// 負責註冊 TTF 字型到系統字型管理器。
    /// 先檢查是否已註冊，避免重複註冊錯誤。
    ///
    /// - Parameter url: TTF 檔案 URL
    /// - Parameter postScriptName: PostScript 名稱
    /// - Parameter size: 字型大小
    /// - Returns: UIFont 物件
    /// - Throws: `CustomError.fontRegisterFailed` 如果註冊失敗
    ///
    /// ## 記憶體管理
    /// 使用 `takeUnretainedValue()` 而非 `takeRetainedValue()`，因為 `CTFontManagerRegisterFontsForURL`
    /// 是 "Get" 函數，不消耗 retain count。
    func loadUIFont(from url: URL, postScriptName: String, size: CGFloat) throws -> UIFont? {
        
        if checkFontRegistered(postScriptName: postScriptName) { return .init(name: postScriptName, size: size) }
        
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        
        if !success {
            if let cfError = error?.takeUnretainedValue() {
                throw CustomError.fontRegisterFailed(path: url.lastPathComponent, error: cfError)
            }
        }
        
        return .init(name: postScriptName, size: size)
    }
    
    /// 載入 TTF 字型（內部方法）
    ///
    /// 從 TTF 檔案讀取 PostScript 名稱，然後註冊字型
    ///
    /// - Parameter url: TTF 檔案 URL
    /// - Parameter size: 字型大小
    /// - Returns: UIFont 物件
    /// - Throws: `CustomError.invalidPostScriptName` 或 `CustomError.fontLoadFailed`
    func loadTTFFont(url: URL, size: CGFloat) throws -> UIFont {
        
        guard let postScriptName = postScriptName(from: url) else { throw CustomError.invalidPostScriptName }
        guard let uiFont = try loadUIFont(from: url, postScriptName: postScriptName, size: size) else { throw CustomError.fontLoadFailed(path: url.path()) }
        
        return uiFont
    }
    
    /// 載入系統內建字型（內部方法）
    ///
    /// 使用系統內建字型，如果不存在則拋出錯誤。
    ///
    /// - Parameter name: PostScript 名稱
    /// - Parameter size: 字型大小
    /// - Returns: UIFont 物件
    /// - Throws: `CustomError.systemFontNotFound` 如果字型不存在
    func loadSystemFont(name: String, size: CGFloat) throws -> UIFont {
        guard let font = UIFont(name: name, size: size) else { throw CustomError.systemFontNotFound(name: name) }
        return font
    }
}
