//
//  CoinService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore

protocol CoinService: class {
  func updateCoins()
  func coins() -> Observable<[Coin]>
  func coins(by term: String) -> Observable<[Coin]>
  func coinExists(name: String) -> Observable<Bool>
  func coinId(symbol: String) -> Int?
  func coinBy(id: Int) -> Coin?
  func coinWith(predicate: (Coin) -> (Bool)) -> Coin?
}
