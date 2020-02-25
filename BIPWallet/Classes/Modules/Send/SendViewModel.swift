//
//  SendViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class SendViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: SendViewModel.Input!
  var output: SendViewModel.Output!
  var dependency: SendViewModel.Dependency!

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
