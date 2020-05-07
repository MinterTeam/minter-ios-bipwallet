//
//  SpendCoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SpendCoinsCoordinator: BaseCoordinator<Void> {

  private var сontroller = SpendCoinsViewController.initFromStoryboard(name: "Convert")

  init(viewController: inout UIViewController?, balanceService: BalanceService, gateService: GateService) {
    super.init()

    let dependency = SpendCoinsViewModel.Dependency(coinService: ExplorerCoinService(),
                                                    balanceService: balanceService,
                                                    gateService: gateService)
    let viewModel = SpendCoinsViewModel(dependency: dependency)
    viewController = сontroller
    (viewController as? SpendCoinsViewController)?.viewModel = viewModel
  }

  override func start() -> Observable<Void> {
    return Observable.never()
  }

}
