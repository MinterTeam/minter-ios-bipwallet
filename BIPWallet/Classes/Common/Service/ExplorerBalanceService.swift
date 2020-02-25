//
//  ExplorerBalanceService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import RxSwift

class ExplorerBalanceService: BalanceService {

  enum ExplorerBalanceServiceError: Error {
    case noAddress
  }

  let httpClient = APIClient()
  lazy var addressManager = ExplorerAddressManager(httpClient: httpClient)

  func balances(address: String) -> Observable<BalancesResponse> {
    return Observable.create { (observer) -> Disposable in
      self.addressManager.address(address: address, withSum: true) { [weak self] (response, err) in

        var totalMainCoinBalance: Decimal = 0
        var totalUSDBalance: Decimal = 0
        var baseCoinBalance: Decimal = 0
        //Second decimal to be used for BIP equivalent
        var allBalances = [String: (Decimal, Decimal)]()

        guard nil == err else {
          observer.onError(err!)
          return
        }

        let address = response ?? [:]
        guard let ads = (address["address"] as? String)?.stripMinterHexPrefix(),
          let coins = address["balances"] as? [[String: Any]] else {
            observer.onError(ExplorerBalanceServiceError.noAddress)
          return
        }

        if let totalBalanceBaseCoin = address["total_balance_sum"] as? String,
          let totalBalance = Decimal(string: totalBalanceBaseCoin) {
          totalMainCoinBalance = totalBalance
        }

        if let totalBalanceUSD = address["total_balance_sum_usd"] as? String,
          let totalBalance = Decimal(string: totalBalanceUSD) {
          totalUSDBalance = totalBalance
        }

        baseCoinBalance = coins.filter({ (dict) -> Bool in
          return ((dict["coin"] as? String) ?? "").uppercased() == Coin.baseCoin().symbol!.uppercased()
        }).map({ (dict) -> Decimal in
          return Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
        }).reduce(0, +)

        if let defaultCoin = Coin.baseCoin().symbol {
          allBalances[defaultCoin] = (0.0, 0.0)
        }
        coins.forEach({ (dict) in
          if let key = dict["coin"] as? String {
            let amnt = Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
            allBalances[key.uppercased()] = (amnt, 0.0)
          }
        })

        let resp = BalancesResponse(totalMainCoinBalance, totalUSDBalance, baseCoinBalance, allBalances)
        observer.onNext(resp)
        observer.onCompleted()
      }

      return Disposables.create()
    }
  }

}

class ExplorerTransactionService: TransactionService {

  let explorerManager = ExplorerTransactionManager(httpClient: APIClient())

  func transactions(address: String, page: Int) -> Observable<[MinterExplorer.Transaction]> {
    return Observable.create { (observable) -> Disposable in
      self.explorerManager.transactions(addresses: [address]) { (transactions, error) in

        guard error == nil else {
          observable.onError(error!)
          return
        }

        observable.onNext(transactions ?? [])
        observable.onCompleted()
      }
      return Disposables.create()
    }
  }

}
