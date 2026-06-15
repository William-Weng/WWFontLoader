//
//  Metrics.swift
//  WWFontLoader
//
//  Created by William.Weng on 2026/6/15.
//

import UIKit
import CoreText

/// 文字尺寸計算工具
///
/// `Metrics` 負責兩件事：
/// 1. 先依容器大小、文字長度與策略，估算適合的字型大小
/// 2. 再依決定好的字型，量測文字在畫面中實際佔用的尺寸
///
/// 這個流程的原因是：
/// - 字型大小只代表「字要多大」
/// - 實際框大小則會受到文字內容、字型特性、換行規則與行數限制影響
/// - 所以即使有了字型大小，文字實際佔用的高度與寬度也不一定能直接用行數推算
///
/// 常見用途：
/// - 單字卡片的動態字級計算
/// - 多行文字的版面預估
/// - 在不同裝置尺寸下維持相對一致的視覺比例
final class Metrics {}

// MARK: - Public
extension Metrics {
    
    /// 只計算字級大小，不回傳文字框尺寸
    ///
    /// 這個方法會先清理文字前後空白與換行，再交給 `calculateFontSize(...)`
    /// 依容器大小、行數與策略推算適合的 point size
    func fontSize(for text: String, in size: CGSize?, maxLines: Int, strategy: WWFontLoader.TextSizeStrategy, fontSize: WWFontLoader.FontSize, fontFactor: WWFontLoader.FontFactor) -> CGFloat {
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return calculateFontSize(for: trimmed, in: size, baseFontSize: fontSize.base, minFontSize: fontSize.min, maxFontSize: fontSize.max, maxLines: maxLines, strategy: strategy, weightFactor: fontFactor.weight, widthFactor: fontFactor.width, heightFactor: fontFactor.height)
    }
    
    /// 計算文字在指定字型下的實際佔用尺寸。
    ///
    /// 這個方法不負責決定字級，而是直接使用傳入的 `font` 去量測文字會佔多少空間 => 適合在你已經有字級後，進一步確認文字是否能放進指定容器
    func textSize(for text: String, font: UIFont, constrainedTo size: CGSize, maxLines: Int, strategy: WWFontLoader.TextSizeStrategy) -> CGSize {
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return measureTextSize(trimmed, font: font, constrainedTo: size, maxLines: maxLines, strategy: strategy)
    }
    
    /// 同時計算字級與文字框尺寸
    ///
    /// 這個方法是 `Metrics` 的整合入口：
    /// - 先依容器大小、文字長度與策略，算出適合的 `fontSize`
    /// - 再用這個字級建立 `UIFont`，量出文字實際的 `textSize`
    ///
    /// 如果 `size == nil`，則只回傳 `fontSize`，`textSize` 會是 `nil`
    func calculate(for text: String, in size: CGSize?, maxLines: Int, strategy: WWFontLoader.TextSizeStrategy, fontSize: WWFontLoader.FontSize, fontFactor: WWFontLoader.FontFactor , font: UIFont?) -> WWFontLoader.SizeResult {

        let fontSizeValue = self.fontSize(for: text, in: size, maxLines: maxLines, strategy: strategy, fontSize: fontSize, fontFactor: fontFactor)

        guard let size else { return (font: fontSizeValue, text: nil) }
        
        let uiFont = font ?? .systemFont(ofSize: fontSizeValue)
        let measuredSize = textSize(for: text, font: uiFont, constrainedTo: size, maxLines: maxLines, strategy: strategy)
        
        return (font: fontSizeValue, text: measuredSize)
    }
}

// MARK: - FontSize
private extension Metrics {
    
    /// 計算最終字級
    ///
    /// 這個方法是 `Metrics` 的主要分派入口：
    /// - 當 `size == nil` 時，只回傳基礎字級，不做容器推算
    /// - 當 `size != nil` 時，會依 `strategy` 決定使用哪一種估算方式
    ///   - `.ratio`：使用 `ratioFontSize(...)`，適合卡片或列表這類快速估算
    ///   - `.boundingRect` / `.sizeWithAttributes` / `.coreText`：使用 `fallbackFontSize(...)` 作為初始字級
    ///
    /// 最後會再把結果限制在 `minFontSize...maxFontSize` 之間，避免過大或過小
    func calculateFontSize(for text: String, in size: CGSize?, baseFontSize: CGFloat, minFontSize: CGFloat, maxFontSize: CGFloat, maxLines: Int, strategy: WWFontLoader.TextSizeStrategy, weightFactor: CGFloat, widthFactor: CGFloat, heightFactor: CGFloat) -> CGFloat {
        
        guard let size else { return min(max(baseFontSize, minFontSize), maxFontSize) }
        
        let computed: CGFloat
        
        switch strategy {
        case .ratio: computed = ratioFontSize(for: text, in: size, maxLines: maxLines, weightFactor: weightFactor, widthFactor: widthFactor, heightFactor: heightFactor)
        case .boundingRect, .sizeWithAttributes, .coreText: computed = fallbackFontSize(for: text, in: size, maxLines: maxLines, weightFactor: weightFactor)
        }
        
        return min(max(computed, minFontSize), maxFontSize)
    }

    /// 依容器大小與文字長度，快速推估字級
    ///
    /// 這是「比例估算」策略，速度快，適合卡片、列表、標題等初步排版
    ///
    /// 計算方式：
    /// 1. 先取容器寬高中的較小者作為基準。
    /// 2. 乘上整體縮放係數 `weightFactor`
    /// 3. 根據文字長度加入衰減係數，字越長，字級越小
    /// 4. 根據允許行數再做一次微調
    func ratioFontSize(for text: String, in size: CGSize, maxLines: Int, weightFactor: CGFloat, widthFactor: CGFloat, heightFactor: CGFloat) -> CGFloat {
        
        let availableWidth = size.width * widthFactor
        let availableHeight = size.height * heightFactor
        let base = min(availableWidth, availableHeight)
        
        let textLength = max(CGFloat(text.count), 1)
        let lengthPenalty = max(0.55, 10.0 / (textLength + 2.0))
        
        let linePenalty: CGFloat = maxLines <= 1 ? 1.0 : 1.0 / CGFloat(maxLines).squareRoot()
        
        return base * weightFactor * lengthPenalty * linePenalty
    }
    
    /// 依容器大小與文字長度，估算備援字級
    ///
    /// 這個方法主要提供給非 `.ratio` 策略使用
    /// 計算邏輯比 `ratioFontSize(...)` 更簡潔，適合作為通用保底公式
    ///
    /// 計算方式：
    /// 1. 直接以容器寬高的較小值作為基準
    /// 2. 乘上整體縮放係數 `weightFactor`
    /// 3. 根據文字長度加入保守的衰減
    /// 4. 根據允許行數做微調
    func fallbackFontSize(for text: String, in size: CGSize, maxLines: Int, weightFactor: CGFloat) -> CGFloat {
        
        let base = min(size.width, size.height)
        let length = max(CGFloat(text.count), 1)
        let lengthPenalty = max(0.55, 12.0 / (length + 4.0))
        let linePenalty: CGFloat = maxLines <= 1 ? 1.0 : 1.0 / CGFloat(maxLines).squareRoot()
        
        return base * weightFactor * lengthPenalty * linePenalty
    }
}

// MARK: - Private
private extension Metrics {
    
    /// 計算文字在指定字型下的實際佔用尺寸
    ///
    /// 這個方法不負責決定字級，而是直接使用傳入的 `font` 去量測文字會佔多少空間，適合在你已經有字級後，進一步確認文字是否能放進指定容器
    ///
    /// - Parameters:
    ///   - text: 要量測的文字
    ///   - font: 用來量測的 `UIFont`
    ///   - size: 可用的容器大小
    ///   - maxLines: 允許的最大行數
    ///   - strategy: 量測策略
    /// - Returns: 文字實際需要的 `CGSize`
    func measureTextSize(_ text: String, font: UIFont, constrainedTo size: CGSize, maxLines: Int, strategy: WWFontLoader.TextSizeStrategy) -> CGSize {
        
        switch strategy {
        case .ratio, .boundingRect: return measureTextSizeByBoundingRect(text, font: font, constrainedTo: size, maxLines: maxLines)
        case .sizeWithAttributes: return measureTextSizeByAttributes(text, font: font)
        case .coreText: return measureTextSizeCoreText(text, font: font, constrainedTo: size, maxLines: maxLines)
        }
    }
    
    /// 依策略量測文字實際尺寸
    ///
    /// 這個方法是統一入口，負責根據 `strategy` 分派到不同的量測方式：
    /// - `.ratio`、`.boundingRect`：使用 `boundingRect(...)`，適合多行文字或有寬度限制的情境
    /// - `.sizeWithAttributes`：使用 `size(withAttributes:)`，適合單行或短文字
    /// - `.coreText`：使用 CoreText 進行更精細的文字量測
    func measureTextSizeByBoundingRect(_ text: String, font: UIFont, constrainedTo size: CGSize, maxLines: Int) -> CGSize {
        
        let maxHeight = CGFloat(maxLines) * font.lineHeight
        let boundingSize = CGSize(width: size.width, height: maxHeight > 0 ? maxHeight : .greatestFiniteMagnitude)
        let rect = (text as NSString).boundingRect(with: boundingSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
    
    /// 使用 `boundingRect(...)` 量測文字實際尺寸
    ///
    /// 這個方法適合多行文字，或需要限制最大寬度與最大行數的情境，會先依 `maxLines` 推算可用高度，再透過 `boundingRect(...)` 得到文字實際佔用空間
    ///
    ///   - text: 要量測的文字
    ///   - font: 用來量測的 `UIFont`
    func measureTextSizeByAttributes(_ text: String, font: UIFont) -> CGSize {
        let rect = (text as NSString).size(withAttributes: [.font: font])
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
    
    /// 使用 CoreText 量測文字在指定容器中的實際尺寸
    ///
    /// 這個方法會建立 `CTFramesetter` 與 `CTFrame`，再逐行取得 `CTLine` 的排版資訊，最後根據每一行的 typographic bounds 與 line origin 推算文字實際佔用的寬高
    ///
    /// 與 `boundingRect(...)` 相比，CoreText 版本更接近真正的排版結果，適合需要精準控制行高、字距、換行與多行文字高度的情境
    ///
    /// 流程：
    /// 1. 將文字轉成 `NSAttributedString`
    /// 2. 建立 `CTFramesetter`
    /// 3. 用指定寬度建立 `CTFrame`
    /// 4. 取得 frame 中所有 line
    /// 5. 逐行計算寬度、ascent、descent、leading 與 line origin
    /// 6. 推算整體文字區塊的寬高
    ///
    /// - Parameters:
    ///   - text: 要量測的文字
    ///   - font: 用來量測的 `UIFont`
    ///   - size: 可用的容器大小
    ///   - maxLines: 允許的最大行數
    ///   - strategy: 量測策略
    /// - Returns: 文字實際需要的 `CGSize`
    func measureTextSizeCoreText(_ text: String, font: UIFont, constrainedTo size: CGSize, maxLines: Int) -> CGSize {
        
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: CGRect(origin: .zero, size: CGSize(width: size.width, height: .greatestFiniteMagnitude)), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(frame) as NSArray
        let lineCount = min(lines.count, maxLines)
        
        guard lineCount > 0 else { return .zero }
        
        var origins = Array(repeating: CGPoint.zero, count: lineCount)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lineCount), &origins)
        
        var maxWidth: CGFloat = 0
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = CGFloat.leastNormalMagnitude
        
        for index in 0..<lineCount {
            
            let line = lines[index] as! CTLine
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
            let origin = origins[index]
            let lineBounds = CGRect(x: origin.x, y: origin.y - descent, width: width, height: ascent + descent + leading)
            
            maxWidth = max(maxWidth, lineBounds.maxX)
            minY = min(minY, lineBounds.minY)
            maxY = max(maxY, lineBounds.maxY)
        }
        
        let height = max(ceil(maxY - minY), font.lineHeight)
        return CGSize(width: ceil(maxWidth), height: ceil(height))
    }
}
