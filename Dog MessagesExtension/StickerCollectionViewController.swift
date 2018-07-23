//
//  StickerCollectionViewController.swift
//  Dog MessagesExtension
//
//  Created by Mike on 7/6/18.
//  Copyright © 2018 Mike. All rights reserved.
//

import UIKit
import Messages

private let reuseIdentifier = "Cell"

class StickerCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    fileprivate let padding: CGFloat = 8
    fileprivate let perRow: CGFloat = 3
    private var stickers = [MSSticker]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        setupStickers()
    }

    private func setupStickers() {
        loadStickers()
    }
    
    private func loadStickers() {
        let dir = "Stickers"
        let bundle = Bundle(for: type(of: self))
        stickers = sortedStickerNames.map { name in
            guard let filename = name.split(separator: ".").first,
                let url = bundle.url(forResource: "/\(dir)/\(filename)", withExtension: "png") else
            {
                return nil
            }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: "")
            }.compactMap { $0 }
    }
    
    private var sortedStickerNames = [
        "dog", "cat", "ok",
        "cute", "woah", "cool",
        "ha", "wyut", "hai",
        "hey2", "help", "hello",
        "no", "sorry", "down",
        "yes", "mine", "call-me",
        "buds", "thank-you", "sup",
        "fish", "ball", "hat",
        "glasses", "wow", "bow",
        "so-smol", "nice", "this",
        "noo", "tell-me-more", "tricks",
        "hey", "never", "aw_baby",
        "butt", "cold", "what",
        "this", "dead", "sad",
    ]
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StickerCell else {
            return UICollectionViewCell()
        }
        cell.stickerView.sticker = stickers[indexPath.row]
        return cell
    }
}

extension StickerCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.size.width - (padding * 4)) / perRow
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
}
