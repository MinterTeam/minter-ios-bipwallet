//
//  BalanceService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import RxSwift

protocol BalanceService {
  typealias BalancesResponse = (
    totalMainCoinBalance: Decimal,
    totalUSDBalance: Decimal,
    baseCoinBalance: Decimal,
    // (Decimal, Decimal).
    // First decimal - balance in custom coin (e.g. BANANA)
    // Second decimal - balance in base coin (e.g. BIP)
    balances: [String: (Decimal, Decimal)]
  )

  var address: Observable<String> {get}

  func balances() -> Observable<BalancesResponse>
  func delegatedBalance() -> Observable<([AddressDelegation]?, Decimal?)>
  func updateBalance()
  func updateDelegated()
}

protocol TransactionService {
  func transactions(address: String, page: Int) -> Observable<[MinterExplorer.Transaction]>
}
