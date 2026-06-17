//
//  WWFontLoader.swift
//  WWFontLoader
//
//  Created by William.Weng on 2026/6/15.
//

import UIKit
import CoreText

/// 字型載入器
///
/// 負責載入系統內建字型和外部的 TTF 字型檔案，支援動態註冊和錯誤處理
final public class WWFontLoader {
    
    public static let shared = WWFontLoader()
    
    private let metrics = Metrics()
}

// MARK: - Public
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

// MARK: - Public
public extension WWFontLoader {

    /// 只計算字級大小，不回傳文字框尺寸
    ///
    /// 這個方法會先清理文字前後空白與換行，再交給 `calculateFontSize(...)`
    /// 依容器大小、行數與策略推算適合的 point size。
    ///
    /// - Parameters:
    ///   - text: 欲進行字級計算的目標文字字串。
    ///   - size: 限制文字佈局的容器尺寸（寬高），若傳入 `nil` 則不限制邊界。
    ///   - maxLines: 文字允許顯示的最大行數，預設為 `1`。
    ///   - strategy: 推算字級時所使用的演算策略，預設為 `.ratio`。
    ///   - fontSize: 字級邊界設定，包含基礎值（base）、最小值（min）與最大值（max）。
    ///   - fontFactor: 字型形變影響因子，包含權重（weight）、寬度（width）與高度（height）。
    /// - Returns: 經過演算法推算出來的最佳字型大小（Point Size）。
    func fontSize(for text: String, in size: CGSize? = nil, maxLines: Int = 1, strategy: TextSizeStrategy = .ratio, fontSize: FontSize, fontFactor: FontFactor) -> CGFloat {
        metrics.fontSize(for: text, in: size, maxLines: maxLines, strategy: strategy, fontSize: fontSize, fontFactor: fontFactor)
    }
    
    /// 計算文字在指定字型下的實際佔用尺寸
    ///
    /// 這個方法不負責決定字級，而是直接使用傳入的 `font` 去量測文字會佔多少空間。
    /// 適合在你已經有字級後，進一步確認文字是否能放進指定容器。
    ///
    /// - Parameters:
    ///   - text: 欲量測佔用空間的目標文字字串。
    ///   - font: 指定用來量測文字空間的 `UIFont` 實例。
    ///   - size: 限制量測範圍的容器尺寸（寬高）。
    ///   - maxLines: 文字允許顯示的最大行數，預設為 `1`。
    ///   - strategy: 空間量測時使用的佈局策略，預設為 `.boundingRect`。
    /// - Returns: 文字在該字型與邊界限制下，實際渲染所佔用的尺寸（CGSize）。
    func textSize(for text: String, font: UIFont, constrainedTo size: CGSize, maxLines: Int = 1, strategy: TextSizeStrategy = .boundingRect) -> CGSize {
        metrics.textSize(for: text, font: font, constrainedTo: size, maxLines: maxLines, strategy: strategy)
    }
    
    /// 同時計算字級與文字框尺寸
    ///
    /// 這個方法是 `Metrics` 的整合入口：
    /// 1. 先依容器大小、文字長度與策略，算出適合的 `fontSize`。
    /// 2. 再用這個字級建立 `UIFont`，量出文字實際的 `textSize`。
    ///
    /// 如果 `size == nil`，則只回傳 `fontSize`，`textSize` 會是 `nil`。
    ///
    /// - Parameters:
    ///   - text: 欲進行完整計算的目標文字字串。
    ///   - size: 限制文字佈局的容器尺寸（寬高），預設為 `nil`（代表不限制邊界）。
    ///   - maxLines: 文字允許顯示的最大行數，預設為 `1`。
    ///   - strategy: 內部演算時所使用的策略，預設為 `.ratio`。
    ///   - fontSize: 字級邊界設定，包含基礎值（base）、最小值（min）與最大值（max）。
    ///   - fontFactor: 字型形變影響因子，預設權重、寬高比為 `(weight: 0.18, width: 0.88, height: 0.70)`。
    ///   - font: 可選傳入的基底字型，若傳入則以此字型為核心進行衍生計算，預設為 `nil`。
    /// - Returns: 包含字級大小與文字框尺寸的整合結果結構（SizeResult）。
    func calculate(for text: String, in size: CGSize? = nil, maxLines: Int = 1, strategy: TextSizeStrategy = .ratio, fontSize: FontSize, fontFactor: FontFactor = (weight: 0.18, width: 0.88, height: 0.70), font: UIFont? = nil) -> SizeResult {
        metrics.calculate(for: text, in: size, maxLines: maxLines, strategy: strategy, fontSize: fontSize, fontFactor: fontFactor, font: font)
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
