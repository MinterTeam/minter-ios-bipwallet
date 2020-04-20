//
//  SpendCoinPickerItem.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore

struct SpendCoinPickerItem {

  var title: String?
  var coin: String?
  var balance: Decimal?

  init(coin: String, balance: Decimal, formatter: NumberFormatter = CurrencyNumberFormatter.coinFormatter) {
    let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: formatter)
    self.title = coin + " (" + balanceString + ")"
    self.coin = coin
    self.balance = balance
  }

  static func items(with balances: [String: Decimal]) -> [SpendCoinPickerItem] {
    var ret = [SpendCoinPickerItem]()
    var coins = balances.keys.filter({ (coin) -> Bool in
      return coin != Coin.baseCoin().symbol!
    }).sorted(by: { (val1, val2) -> Bool in
      return val1 < val2
    })
    coins.insert(Coin.baseCoin().symbol!, at: 0)
    coins.forEach({ (coin) in
      let balance = (balances[coin] ?? 0.0)
      let item = SpendCoinPickerItem(coin: coin,
                                     balance: balance)
      ret.append(item)
    })
    return ret
  }

}
