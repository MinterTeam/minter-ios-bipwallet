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
  func currentGas() -> Observable<Int>
  func updateGas()
}
