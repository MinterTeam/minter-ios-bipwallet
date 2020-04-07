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
    var viewDidDisappear: AnyObserver<Void>
  }

  struct Output {
    var viewDidDisappear: Observable<Void>
  }

  struct Dependency {}

  init(dependency: Dependency) {
    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver())
    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable())
    self.dependency = dependency

    super.init()
  }

  // MARK: -

  private var viewDidDisappear = PublishSubject<Void>()

}
