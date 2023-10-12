//
//  ExplorerGateService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 24.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

class ExplorerGateService: GateService {

  init() {
    self.priceCommissions().subscribe().disposed(by: disposeBag)
  }

  func priceCommissions() -> Observable<(Decimal?)> {
    return gateManager.priceCommissions()
  }

  var lastComission: Commission? {
    return gateManager.lastComission
  }

  private let disposeBag = DisposeBag()

  private let gateManager = GateManager(httpClient: APIClient(headers: ["X-Minter-Chain-Id": XMinterChainId]))

  private let gasSubject = ReplaySubject<Int>.create(bufferSize: 1)

  func currentGas() -> Observable<Int> {
    return gasSubject.asObserver()
  }

  func commission() -> Observable<Commission> {
    return gateManager.commissionSubject
  }

  func updateGas() {
    gateManager.minGas().subscribe(gasSubject).disposed(by: disposeBag)
  }

  func nonce(address: String) -> Observable<Int> {
    return gateManager.nonce(address: address)
  }

  func send(rawTx: String?) -> Observable<(String?, Decimal?)> {
    return gateManager.send(rawTx: rawTx)
  }

  func estimateComission(rawTx: String) -> Observable<Decimal> {
    gateManager.estimateComission(tx: rawTx)
  }

  func estimateCoinBuy(coinFrom: String,
                       coinTo: String,
                       value: Decimal) -> Observable<EstimateConvertResponse> {
    return Observable.create { (observer) -> Disposable in
      self.gateManager.estimateCoinBuy(coinFrom: coinFrom, coinTo: coinTo, value: value) { (res, error) in
        if let error = error {
          observer.onError(error)
        } else if res == nil {
          observer.onError(GateManagerError.wrongResponse)
        } else {
          observer.onNext(res!)
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

}
