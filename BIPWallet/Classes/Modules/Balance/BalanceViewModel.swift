//
//  BalanceViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class BalanceViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private var needsToUpdateBalance = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: BalanceViewModel.Input!
  var output: BalanceViewModel.Output!
  var dependency: BalanceViewModel.Dependency!

  struct Input {
    var needsToUpdateBalance: AnyObserver<Void>
  }

  struct Output {
    
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  init(dependency: Dependency) {
    self.input = Input(needsToUpdateBalance: needsToUpdateBalance.asObserver())
    self.output = Output()
    self.dependency = dependency

    super.init()
  }

  // MARK: -

}
