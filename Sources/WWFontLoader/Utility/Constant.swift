//
//  Constant.swift
//  WWFontLoader
//
//  Created by William.Weng on 2026/6/12.
//

import Foundation

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
}
