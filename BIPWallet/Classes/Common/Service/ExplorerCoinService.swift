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

  private let manager = ExplorerCoinManager(httpClient: APIClient())

  func coins(by term: String) -> Observable<[Coin]> {
    return Observable.create { (observer) -> Disposable in
      self.manager.coins(term: term) { (coins, error) in
        guard error == nil else {
          observer.onError(error!)
          return
        }
        observer.onNext(coins ?? [])
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func coinExists(name: String) -> Observable<Bool> {
    return Observable.create { (observer) -> Disposable in
      self.manager.coins(term: name) { (coins, error) in
        guard error == nil else {
          observer.onError(error!)
          return
        }
        if let coin = coins?.first, (coin.symbol ?? "") == name {
          observer.onNext(true)
        } else {
          observer.onNext(false)
        }
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

}
