//
//  AccountItem.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

//🐬 Дельфин – самый умный – 100 и более миллинов бипов, то есть 1% и более процентов сети Minter!
//🐋 Кит сети Minter – это аккаунт с суммой бипов, делегированных и в монетах, более 10 миллионов, то есть 0.1% от конечной эмиссии.
//🦈 Акула – аккаунт с миллионом и более бипов.
//🐠 Красивая тропическая рыбка – от 100 тысяч бипов.
//🦀 Крабы – 10 и более тысяч бипов.
//🐚 Ракушки – от 1000 до 10000 бипов.
//🎐 Медуза – незаметные для сети участники с суммой менее 1000 бипов.

class AccountItem {
  var emoji = "🐠"
  var title: String?
  var address: String
  var lastSelected: Date

  init(title: String?, address: String) {
    self.title = title
    self.address = address
    self.lastSelected = Date()
  }

  convenience init(title: String?, address: String, emoji: String, lastSelected: Date) {
    self.init(title: title, address: address)
    self.emoji = emoji
    self.lastSelected = lastSelected
  }
  
  static func emoji(for balance: Decimal) -> String {
    if balance < 1000 {
      return "🎐"
    } else if balance < 10000 {
      return "🐚"
    } else if balance < 100000 {
      return "🦀"
    } else if balance < 1000000 {
      return "🐠"
    } else if balance < 10000000 {
      return "🦈"
    } else if balance < 100000000 {
      return "🐋"
    } else {
      return "🐬"
    }
  }

}
