//
//  CircleView.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-03-06.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

class CircleView: UIView {

    var circleLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
            radius: (frame.size.width - 10)/2,
            startAngle: CGFloat(.pi * 1.5),
            endAngle: CGFloat(.pi * -0.5),
            clockwise: false
        )
        
        circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = kCALineCapRound;
        circleLayer.strokeColor = UIColor.init(red: 1.0, green: 0.46, blue: 0.43, alpha: 1).cgColor
        circleLayer.lineWidth = 10;
        circleLayer.strokeEnd = 0.0

        layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateCircle(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.duration = duration
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        circleLayer.strokeEnd = 1.0
        circleLayer.add(animation, forKey: "animateCircle")
    }

}
