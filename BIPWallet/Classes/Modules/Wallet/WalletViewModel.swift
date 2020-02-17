//
//  WalletViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class WalletViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: WalletViewModel.Input!
  var output: WalletViewModel.Output!
  var dependency: WalletViewModel.Dependency!

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
