//
//  BalanceViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 13/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class BalanceViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: BalanceViewModel.Input!
  var output: BalanceViewModel.Output!
  var dependency: BalanceViewModel.Dependency!

  struct Input {

  }

  struct Output {

  }

  struct Dependency {

  }

  init(dependency: Dependency) {
    self.input = Input()
    self.output = Output()
    self.dependency = dependency

    super.init()
  }

  // MARK: -

}
