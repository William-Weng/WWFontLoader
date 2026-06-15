//
//  Constant.swift
//  WWFontLoader
//
//  Created by William.Weng on 2026/6/12.
//

import Foundation

// MARK: - typealias
public extension WWFontLoader {
    
    /// 字級與文字框尺寸的計算結果 (依容器與策略推估出的字型大小, 使用該字型後，文字實際佔用的尺寸 => 當只需要字級時，可為 `nil`)
    typealias SizeResult = (font: CGFloat, text: CGSize?)
    
    /// 字級設定 (基礎字級, 字級下限, 字級上限)
    typealias FontSize = (base: CGFloat, min: CGFloat, max: CGFloat)
    
    /// 字級縮放因子 (整體縮放權重, 寬度安全係數, 高度安全係數)
    typealias FontFactor = (weight: CGFloat, width: CGFloat, height: CGFloat)
}

// MARK: - enum
public extension WWFontLoader {
    
    /// 自訂字型載入錯誤
    ///
    /// 用於處理字型載入過程中可能遇到的各種錯誤情況，支援詳細的錯誤訊息輸出
    enum CustomError: Error, CustomStringConvertible {
        
        case systemFontNotFound(name: String)
        case fontNotFound(path: String)
        case fontLoadFailed(path: String)
        case fontRegisterFailed(path: String, error: CFError)
        case invalidPostScriptName
        
        public var description: String {
            
            switch self {
            case .systemFontNotFound(let name): return "❌ 找不到已註冊字型: \(name)"
            case .fontNotFound(let path): return "❌ 找不到字型檔案: \(path)"
            case .fontLoadFailed(let path): return "❌ 無法載入字型: \(path)"
            case .fontRegisterFailed(let path, let error): return "❌ 字型註冊失敗: \(path), \(error)"
            case .invalidPostScriptName: return "❌ 無效的 PostScript 名稱"
            }
        }
    }
    
    /// 字型來源
    ///
    /// 定義字型是來自系統內建字型還是外部 TTF 檔案
    enum FontSource {
        case system(postScriptName: String, size: CGFloat)  // 系統內建字型
        case ttf(url: URL, size: CGFloat)                   // 外部 TTF 檔案
    }
    
    /// 文字尺寸計算策略
    ///
    /// 用來決定 `Metrics` 以哪一種方式計算字級或文字框大小
    enum TextSizeStrategy {
        
        case ratio                  // 比例估算 => 依照容器大小、字數與行數進行快速推算，速度快，適合卡片或列表的初步排版
        case boundingRect           // 使用 `NSString.boundingRect(...)` 量測 => 適合多行文字與一般排版需求，通常是最常用也最穩定的方式
        case sizeWithAttributes     // 使用 `NSString.size(withAttributes:)` 量測 => 適合單行或較短文字，API 簡單，但對多行與段落控制較弱
        case coreText               // 使用 CoreText 量測 => 適合需要更底層與更精準文字排版控制的情境，例如複雜行距、字距或進階排版
    }
}
