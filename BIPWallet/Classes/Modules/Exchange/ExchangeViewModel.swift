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
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.timer(0, period: 0.5, scheduler: MainScheduler.instance).map {_ in}).merge()

  var lastUpdated: Observable<NSAttributedString?> {
    return balanceTitleObservable.withLatestFrom(self.dependency.balanceService.lastBlockAgo()).map {
     let ago = Date().timeIntervalSince1970 - ($0 ?? 0)
     return self.headerViewLastUpdatedTitleText(seconds: ago)
    }
  }

  func bind() {

  }

  func headerViewLastUpdatedTitleText(seconds: TimeInterval) -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Last updated ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 12.0)]))
    var dateText = "\(Int(seconds)) seconds"
    if seconds < 5 {
      dateText = "just now".localized()
    } else if seconds > 60 * 60 {
      dateText = "more than an hour".localized()
    } else if seconds > 60 {
      dateText = "more than a minute".localized()
    }
    string.append(NSAttributedString(string: dateText,
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 12.0)]))
    if seconds >= 5 {
      string.append(NSAttributedString(string: " ago".localized(),
                                       attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                    .font: UIFont.defaultFont(of: 12.0)]))
    }
    return string
  }

}
