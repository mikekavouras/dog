//
//  StickerViewController.swift
//  Dog MessagesExtension
//
//  Created by Mike on 7/5/18.
//  Copyright © 2018 Mike. All rights reserved.
//

import UIKit
import Messages

class StickerViewController: MSStickerBrowserViewController {
    private var stickers = [MSSticker]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStickers()
        
        view.backgroundColor = UIColor(red: 241/255.0, green: 203/255.0, blue: 202/255.0, alpha: 1.0)
    }
    
    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return stickers.count
    }
    
    override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        return stickers[index]
    }
    
    private func loadStickers() {
        let dir = "Stickers"
        let bundle = Bundle(for: type(of: self))
        stickers = sortedStickerNames.map { name in
            guard let filename = name.split(separator: ".").first,
                  let url = bundle.url(forResource: "/\(dir)/with-background", withExtension: "png") else
            {
                return nil
            }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: "")
        }.compactMap { $0 }
    }
    
    private var sortedStickerNames = [
        "dog", "cat", "ok", "cute",
        "woah", "cool", "ha", "wyut",
        "hai", "hey", "help", "hello",
        "no", "sorry", "down", "yes",
        "mine", "call-me", "buds", "sup",
        "sad", "fish", "ball", "hat",
        "glasses", "poop", "bow", "wow",
        "nice", "thank-you", "smol",
        "tell-me-more", "noo", "tricks",
        "hey2", "this"
    ]
}
