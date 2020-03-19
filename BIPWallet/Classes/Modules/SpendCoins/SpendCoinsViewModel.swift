//
//  SpendCoinsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class SpendCoinsViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: SpendCoinsViewModel.Input!
  var output: SpendCoinsViewModel.Output!
  var dependency: SpendCoinsViewModel.Dependency!

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
