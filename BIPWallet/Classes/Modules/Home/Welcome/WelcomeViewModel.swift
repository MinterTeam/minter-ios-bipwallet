//
//  BIPWelcomeViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//


import Foundation
import RxSwift

class WelcomeViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: WelcomeViewModel.Input!
  var output: WelcomeViewModel.Output!
  var dependency: WelcomeViewModel.Dependency!

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
