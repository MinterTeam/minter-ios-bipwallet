//
//  ExchangeViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ExchangeViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: ExchangeViewModel.Input!
  var output: ExchangeViewModel.Output!
  var dependency: ExchangeViewModel.Dependency!

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
