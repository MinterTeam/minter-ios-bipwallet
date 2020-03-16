//
//  TransactionViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class TransactionViewModel: BaseViewModel, ViewModel {

  // MARK: -

  var didDismiss = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: TransactionViewModel.Input!
  var output: TransactionViewModel.Output!
  var dependency: TransactionViewModel.Dependency!

  struct Input {

  }

  struct Output {
    var didDismiss: Observable<Void>
  }

  struct Dependency {

  }

  init(dependency: Dependency) {
    self.input = Input()
    self.output = Output(didDismiss: didDismiss.asObservable())
    self.dependency = dependency

    super.init()
  }

  // MARK: -

}
