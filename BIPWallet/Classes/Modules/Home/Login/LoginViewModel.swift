//
//  LoginViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class LoginViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: LoginViewModel.Input!
  var output: LoginViewModel.Output!
  var dependency: LoginViewModel.Dependency!

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
