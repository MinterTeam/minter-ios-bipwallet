//
//  UIView+ShakeError.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

extension UIView {

  func shakeError(offset: CGFloat = 10.0, duration: Double = 0.07, repeatCount: Float = 4) {
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = duration
    animation.repeatCount = repeatCount
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - offset,
                                                   y: self.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + offset,
                                                 y: self.center.y))
    self.layer.add(animation, forKey: "position")
  }

}
