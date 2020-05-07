//
//  WalletSelectableViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 24.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol WalletSelectableViewModel {
  var balanceService: BalanceService! { get }
  func walletObservable() -> Observable<String?>
  func showWalletObservable() -> Observable<Void>
}

extension WalletSelectableViewModel {

  func walletObservable() -> Observable<String?> {
    return Observable.of(self.balanceService.account.map {_ in}, self.balanceService.balances().map{_ in}).merge()
      .withLatestFrom(self.balanceService.account)
      .map { (item) -> String? in
        let title = (item?.title ?? TransactionTitleHelper.title(from: item?.address ?? ""))
        return (item?.emoji ?? "") + "  " + title
    }
  }
}
