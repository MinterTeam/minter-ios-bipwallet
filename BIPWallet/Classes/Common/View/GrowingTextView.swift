//
//  AddressTextView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 12/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class GrowingTextView: AutoGrowingTextView {

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.bounces = false
		self.showsVerticalScrollIndicator = false
	}
}

class UsernameGrowingTextView: GrowingTextView {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    self.textContainerInset = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 14.0, right: 32.0)
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    switch action {
    case #selector(paste(_:)):
      return true
    default:
      return super.canPerformAction(action, withSender: sender)
    }
  }

}

class PayloadGrowingTextView: GrowingTextView {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    self.textContainerInset = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 14.0, right: 34.0)
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    switch action {
    case #selector(paste(_:)):
      return true
    default:
      return super.canPerformAction(action, withSender: sender)
    }
  }

}
 
