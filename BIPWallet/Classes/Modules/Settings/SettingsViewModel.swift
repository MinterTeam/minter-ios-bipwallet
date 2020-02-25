//
//  SettingsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class SettingsViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: SettingsViewModel.Input!
  var output: SettingsViewModel.Output!
  var dependency: SettingsViewModel.Dependency!

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
