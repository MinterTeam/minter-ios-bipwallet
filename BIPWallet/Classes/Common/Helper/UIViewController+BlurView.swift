//
//  UIViewController+BlurView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import SnapKit

fileprivate let blurViewTag = 747

extension UIViewController {

  func showBlurOverview() {
    let blurSubview = view.subviews.filter { (aView) -> Bool in
      return (aView.tag == blurViewTag && aView.classForCoder == UIVisualEffectView.classForCoder())
    }.first

    guard blurSubview == nil else {
      UIView.animate(withDuration: 0.25) {
        blurSubview?.alpha = 1.0
      }
      return
    }
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    effectView.alpha = 0.0
    effectView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(effectView)
    effectView.frame = view.bounds
    effectView.tag = blurViewTag
    effectView.snp.makeConstraints { (maker) in
      maker.top.equalTo(self.view).offset(-1000)
      maker.left.equalTo(self.view).offset(0)
      maker.right.equalTo(self.view).offset(0)
      maker.bottom.equalTo(self.view).offset(0)
    }

    UIView.animate(withDuration: 0.25) {
      effectView.alpha = 1.0
    }

  }

  func hideBlueOverview() {
    guard let blurView = (view.subviews.filter { (aView) -> Bool in
      return (aView.tag == blurViewTag && aView.classForCoder == UIVisualEffectView.classForCoder())
    }.first) else {
      return
    }

    UIView.animate(withDuration: 0.25) {
      blurView.alpha = 0.0
    }
  }

}
