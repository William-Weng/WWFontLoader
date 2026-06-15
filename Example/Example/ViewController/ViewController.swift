//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/6/15.
//

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
