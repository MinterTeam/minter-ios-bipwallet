//
//  CoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState

class CoinsCoordinator: BaseCoordinator<Void> {

  var didScrollToPoint: Observable<CGPoint>?
  var didTapExchangeButton = PublishSubject<Void>()

  var viewController: CoinsViewController?

  let balanceService: BalanceService

  init(balanceService: BalanceService) {
    self.balanceService = balanceService
  }

  override func start() -> Observable<Void> {
    let controller = CoinsViewController.initFromStoryboard(name: "Coins")

    let localAuthService = LocalStorageAuthService()
    guard let account = localAuthService.selectedAccount() else {
      return Observable.empty()
    }

    let dependency = CoinsViewModel.Dependency(balanceService: balanceService)
    let viewModel = CoinsViewModel(dependency: dependency)

    controller.viewModel = viewModel
    self.viewController = controller

    didScrollToPoint = controller.rx.viewDidLoad.flatMap({ (_) -> Observable<CGPoint> in
      return controller.tableView.rx.didScroll.map { (_) -> CGPoint in
        return controller.tableView.contentOffset
      }
    })

    viewModel
      .output
      .didTapExchangeButton
      .asDriver(onErrorJustReturn: ())
      .drive(didTapExchangeButton)
      .disposed(by: disposeBag)

    return Observable.never()
  }

}
