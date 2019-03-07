//
//  ColorButton.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-03-01.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

@IBDesignable
class ColorButton: UIView {
    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear
    @IBInspectable var borderColor: UIColor = UIColor.clear
    
    override func draw(_ rect: CGRect) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: CGFloat(0),
                                y: CGFloat(0),
                                width: superview!.frame.size.width,
                                height: superview!.frame.size.height)
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = CGPoint(x: -1, y: -1)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.zPosition = -1
        layer.addSublayer(gradient)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 30
        self.layer.borderWidth = 4
        self.layer.borderColor = borderColor.cgColor
    }
}
