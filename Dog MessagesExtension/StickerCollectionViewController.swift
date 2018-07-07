//
//  StickerCollectionViewController.swift
//  Dog MessagesExtension
//
//  Created by Mike on 7/6/18.
//  Copyright © 2018 Mike. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class StickerCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    fileprivate let padding: CGFloat = 8
    fileprivate let perRow: CGFloat = 3

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        setupCollectionView()
        setupStickers()
    }
    
    private func setupCollectionView() {
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    private func setupStickers() {
        loadStickers()
    }
    
    private func loadStickers() {
        
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StickerCell else {
            return UICollectionViewCell()
        }
        cell.backgroundColor = .red
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
