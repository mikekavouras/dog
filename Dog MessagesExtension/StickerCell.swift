//
//  StickerCell.swift
//  Dog MessagesExtension
//
//  Created by Mike on 7/6/18.
//  Copyright © 2018 Mike. All rights reserved.
//

import UIKit
import Messages

class StickerCell: UICollectionViewCell {
    
    @IBOutlet weak var stickerView: MSStickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make backgrounds transparent so the Liquid Glass effect shows through
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        stickerView?.backgroundColor = .clear
        
        // Remove any default shadows/effects from all layers
        layer.shadowOpacity = 0
        layer.borderWidth = 0
        contentView.layer.shadowOpacity = 0
        contentView.layer.borderWidth = 0
        stickerView?.layer.shadowOpacity = 0
        stickerView?.layer.borderWidth = 0
    }
}
