//
//  StickerPreviewCell.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-03-01.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

class StickerCell: UICollectionViewCell {
    @IBOutlet var thumbnail: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = false
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        
        let shadowLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: self.layer.bounds, cornerRadius: 16).cgPath
            layer.fillColor = UIColor.white.cgColor
            layer.shadowColor = UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.09).cgColor
            layer.shadowPath = layer.path
            layer.shadowOffset = CGSize(width: 0, height: 2.0)
            layer.shadowOpacity = 0.8
            layer.shadowRadius = 4
            return layer
        }()
        
        self.layer.insertSublayer(shadowLayer, at: 0)
    }
    
    public func configure(with sticker : Sticker) {
        self.thumbnail.image = UIImage(data: sticker.stickerData)  // renders as a still image
        self.thumbnail.layer.cornerRadius = 16
        self.thumbnail.clipsToBounds = true
    }

}
