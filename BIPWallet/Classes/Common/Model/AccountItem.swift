//
//  AccountItem.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

class AccountItem {
  var emoji = "🐠"
  var title: String
  var address: String

  init(title: String, address: String) {
    self.title = title
    self.address = address
  }

  convenience init(title: String, address: String, emoji: String) {
    self.init(title: title, address: address)
    self.emoji = emoji
  }

}
