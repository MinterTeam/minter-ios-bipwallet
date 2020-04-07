//
//  PassthroughView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 06.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

protocol PassthroughViewDelegate: class {
  func willPassHitWith(point: CGPoint, event: UIEvent?)
}

class PassthroughView: UIView {

  weak var passView: UIView?
  weak var delegate: PassthroughViewDelegate?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard let view = super.hitTest(point, with: event) else {
      return nil
    }
    guard view === self, let point = passView?.convert(point, from: self) else {
      return view
    }
    delegate?.willPassHitWith(point: point, event: event)
    return passView?.hitTest(point, with: event)
  }
}
