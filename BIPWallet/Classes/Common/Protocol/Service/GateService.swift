//
//  GateService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 24.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol GateService {
  func updateGas()
  func currentGas() -> Observable<Int>
  func nonce(address: String) -> Observable<Int>
  func send(rawTx: String?) -> Observable<(String?, Decimal?)>
  func estimateComission(rawTx: String) -> Observable<Decimal>
  func priceCommissions() -> Observable<(Decimal?)>
  var lastComission: Commission? { get }
  func commission() -> Observable<Commission>
  func estimateCoinBuy(coinFrom: String,
                       coinTo: String,
                       value: Decimal) -> Observable<EstimateConvertResponse>
}
