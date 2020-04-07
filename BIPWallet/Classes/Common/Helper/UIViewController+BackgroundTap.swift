//
//  UIViewController+BackgroundTap.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 01.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

extension UIView {

  func addBackgroundTapGesture(action: @escaping () -> Void) {
    let tap = BackgroundTapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
    tap.action = action
    tap.numberOfTapsRequired = 1

    self.addGestureRecognizer(tap)
    self.isUserInteractionEnabled = true
  }

  @objc func handleTap(_ sender: BackgroundTapGestureRecognizer) {
    sender.action!()
  }
}

class BackgroundTapGestureRecognizer: UITapGestureRecognizer {
  var action: (() -> Void)? = nil
}
