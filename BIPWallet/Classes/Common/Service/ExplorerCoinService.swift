//
//  ExplorerCoinService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

class ExplorerCoinService: CoinService {

  init() {
    loadCoins()
  }

  private let manager = ExplorerCoinManager(httpClient: APIClient())

  private var allCoins = [Coin]()

  private let disposeBag = DisposeBag()

  func updateCoins() {
    loadCoins()
  }

  private func loadCoins() {
    manager.coins(term: "").map { (coins) -> [Coin] in
      return coins ?? []
    }.filter({ (coins) -> Bool in
      return coins.count > 0
    }).subscribe(onNext: { (coins) in
      self.allCoins = coins.map({ (coin) -> Coin in
        if (coin.symbol ?? "") == Coin.baseCoin().symbol! {
          coin.reserveBalance = Decimal.greatestFiniteMagnitude
        }
        return coin
      })
    }).disposed(by: disposeBag)
  }

  func coins(by term: String) -> Observable<[Coin]> {
    return Observable.create { (observer) -> Disposable in
      let term = term.lowercased()
      let coins = self.allCoins.filter { (con) -> Bool in
        return (con.symbol ?? "").lowercased().starts(with: term)
      }.sorted(by: { (coin1, coin2) -> Bool in
        if term == (coin1.symbol ?? "").lowercased() {
          return true
        } else if (coin2.symbol ?? "").lowercased() == term {
          return false
        }
        return (coin1.reserveBalance ?? 0) > (coin2.reserveBalance ?? 0)
      })
      observer.onNext(coins)
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func coinExists(name: String) -> Observable<Bool> {
    return Observable.create { (observer) -> Disposable in
      observer.onNext(self.allCoins.contains(where: { (coin) -> Bool in
        return (coin.symbol ?? "").lowercased() == name.lowercased()
      }))
      observer.onCompleted()
//      self.manager.coins(term: name) { (coins, error) in
//        guard error == nil else {
//          observer.onError(error!)
//          return
//        }
//        if let coin = coins?.first, (coin.symbol ?? "") == name {
//          observer.onNext(true)
//        } else {
//          observer.onNext(false)
//        }
//        observer.onCompleted()
//      }
      return Disposables.create()
    }
  }

}

enum ExplorerCoinManagerRxError : Error {
  case noCoin
}

extension ExplorerCoinManager {

  func coin(by term: String) -> Observable<Coin?> {
    return Observable.create { (observer) -> Disposable in
      self.coins(term: term) { (coins, error) in

        guard error == nil else {
          observer.onError(error!)
          return
        }
        if let coin = coins?.filter({ (coin) -> Bool in
          return coin.symbol?.lowercased() == term.lowercased()
        }).first {
          observer.onNext(coin)
        } else {
          observer.onNext(nil)
        }
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func coins(term: String) -> Observable<[Coin]?> {
    return Observable.create { (observer) -> Disposable in
      self.coins(term: term) { (coins, error) in

        guard error == nil else {
          observer.onError(error!)
          return
        }

        observer.onNext(coins)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }
}
