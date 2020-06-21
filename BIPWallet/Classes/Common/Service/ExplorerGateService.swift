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

class ExplorerGateService: GateService {

  private let disposeBag = DisposeBag()

  private let gateManager = GateManager(httpClient: APIClient())

  private let gasSubject = ReplaySubject<Int>.create(bufferSize: 1)

  func currentGas() -> Observable<Int> {
    return gasSubject.asObserver()
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

}
