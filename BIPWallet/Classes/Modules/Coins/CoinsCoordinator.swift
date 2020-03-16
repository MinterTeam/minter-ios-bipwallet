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

  var viewController: CoinsViewController?

  let balanceService: ExplorerBalanceService

  init(balanceService: ExplorerBalanceService) {
    self.balanceService = balanceService
  }

  override func start() -> Observable<Void> {
    let controller = CoinsViewController.initFromStoryboard(name: "Coins")

    let localAuthService = LocalStorageAuthService()
    guard let account = localAuthService.selectedAccount() else {
      return Observable.empty()
    }

    let viewModel = CoinsViewModel(dependency: CoinsViewModel.Dependency(balanceService: balanceService))

    controller.viewModel = viewModel
    self.viewController = controller

    self.didScrollToPoint = controller.rx.viewDidLoad.flatMap({ (_) -> Observable<CGPoint> in
      return controller.tableView.rx.didScroll.map { (_) -> CGPoint in
        return controller.tableView.contentOffset
      }
    })

    return Observable.never()
  }

}
