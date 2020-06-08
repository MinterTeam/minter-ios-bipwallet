//
//  ValidatorItem.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

struct ValidatorItem {
  var iconURL: URL?
  var publicKey: String
  var name: String?
  var isOnline: Bool = false
  var stake: Decimal = 0

  init?(publicKey: String, name: String? = nil) {
    guard publicKey.isValidPublicKey() else {
      return nil
    }
    self.publicKey = publicKey
  }
}
