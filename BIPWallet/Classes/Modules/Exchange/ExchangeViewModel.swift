//
//  ExchangeViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ExchangeViewModel: BaseViewModel, ViewModel, LastBlockViewable {

  // MARK: - ViewModel

  var input: ExchangeViewModel.Input!

  var output: ExchangeViewModel.Output!

  var dependency: ExchangeViewModel.Dependency!

  struct Input {
    var viewDidDisappear: AnyObserver<Void>
  }

  struct Output {
    var viewDidDisappear: Observable<Void>
    var lastUpdated: Observable<NSAttributedString?>
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver()
    )

    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable(),
                         lastUpdated: lastUpdated
    )

    bind()
  }

  // MARK: -

  private var viewDidDisappear = PublishSubject<Void>()
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance).map {_ in}).merge()

  var lastUpdated: Observable<NSAttributedString?> {
    return balanceTitleObservable.withLatestFrom(self.dependency.balanceService.lastBlockAgo()).map {
     let ago = Date().timeIntervalSince1970 - ($0 ?? 0)
     return self.headerViewLastUpdatedTitleText(seconds: ago)
    }
  }

  func bind() {}

}
