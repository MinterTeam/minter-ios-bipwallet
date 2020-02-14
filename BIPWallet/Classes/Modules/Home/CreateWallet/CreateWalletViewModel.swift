//
//  CreateWalletViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class CreateWalletViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: CreateWalletViewModel.Input!
  var output: CreateWalletViewModel.Output!
  var dependency: CreateWalletViewModel.Dependency!

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
