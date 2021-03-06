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

enum BalanceServiceError: Error {
  case incorrectAddress
}

protocol BalanceService {
  typealias BalancesResponse = (
    address: String,
    totalMainCoinBalance: Decimal,
    totalUSDBalance: Decimal,
    baseCoinBalance: Decimal,
    // (Decimal, Decimal).
    // First decimal - balance in custom coin (e.g. BANANA)
    // Second decimal - balance in base coin (e.g. BIP)
    balances: [String: (Decimal, Decimal)]
  )

  var account: Observable<AccountItem?> {get}

  func changeAddress(_ address: String) throws
  func balances() -> Observable<BalancesResponse>
  func delegatedBalance() -> Observable<(String?, [AddressDelegation]?, Decimal?)>
  func updateBalance()
  func updateDelegated()
  func lastBlockAgo() -> Observable<TimeInterval?>

  func balances(address: String) -> Observable<BalancesResponse>
}
