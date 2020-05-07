//
//  UIViewController+BlurView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

fileprivate let blurViewTag = 747

extension UIViewController {

  func showBlurOverview(style: UIBlurEffect.Style = .dark, tapAction: (() -> ())? = nil) {
    let blurSubview = findBlurView()

    guard blurSubview == nil else {
      return
    }

    let effectViewWrapper = UIView(frame: view.bounds)
    effectViewWrapper.alpha = 0.0
    effectViewWrapper.translatesAutoresizingMaskIntoConstraints = false
    effectViewWrapper.tag = blurViewTag
    effectViewWrapper.backgroundColor = UIColor(hex: 0x282240, alpha: 0.8)

    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
    effectView.alpha = 0.0
    effectView.translatesAutoresizingMaskIntoConstraints = false
    effectViewWrapper.addSubview(effectView)
    effectView.frame = view.bounds

    defer {
      UIView.animate(withDuration: 0.5) {
        effectViewWrapper.alpha = 1.0
        effectView.alpha = 1.0
      }
    }

    effectView.snp.makeConstraints { (maker) in
      maker.top.equalTo(effectViewWrapper).offset(0)
      maker.left.equalTo(effectViewWrapper).offset(0)
      maker.right.equalTo(effectViewWrapper).offset(0)
      maker.bottom.equalTo(effectViewWrapper).offset(0)
    }

    self.view.addSubview(effectViewWrapper)
    effectViewWrapper.snp.makeConstraints { (maker) in
      maker.top.equalTo(self.view).offset(-2000)
      maker.left.equalTo(self.view).offset(0)
      maker.right.equalTo(self.view).offset(0)
      maker.bottom.equalTo(self.view).offset(0)
    }

    effectViewWrapper.addBackgroundTapGesture {
      tapAction?()
    }

    self.view.sendSubviewToBack(effectViewWrapper)
  }

  func hideBlurOverview() {
    guard let blurView = findBlurView() else { return }

    UIView.animate(withDuration: 0.25, animations: {
      blurView.alpha = 0.0
    }) { (completed) in
      if completed {
        blurView.removeFromSuperview()
      }
    }
  }

  func updateBlurView(percentage: CGFloat) {
    let newPercentage = percentage

    let blurView = findBlurView()
    blurView?.alpha = max(min(newPercentage, 1.0), 0)
  }

  func findBlurView() -> UIView? {
    return view.subviews.filter { (aView) -> Bool in
      return (aView.tag == blurViewTag)
    }.first
  }

  @objc func blurViewDidTap() {
    hideBlurOverview()
  }

}
