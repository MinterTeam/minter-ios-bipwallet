//
//  ExchangeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

class ExchangeCoordinator: BaseCoordinator<Void> {

  let rootController: UIViewController
  let balanceService: BalanceService

  init(rootController: UIViewController, balanceService: BalanceService) {
    self.rootController = rootController
    self.balanceService = balanceService
  }

  override func start() -> Observable<Void> {
    let dependency = ExchangeViewModel.Dependency()
    let viewModel = ExchangeViewModel(dependency: dependency)
    let viewController = ExchangeViewController.initFromStoryboard(name: "Exchange")
    viewController.viewModel = viewModel

    var getViewController: UIViewController?
    var spendViewController: UIViewController?

    let gateService = ExplorerGateService()

    let spend = SpendCoinsCoordinator(viewController: &spendViewController,
                                      balanceService: balanceService,
                                      gateService: gateService
                                      )

    let get = GetCoinsCoordinator(viewController: &getViewController,
                                  balanceService: balanceService,
                                  gateService: gateService
                                  )

    coordinate(to: spend).subscribe().disposed(by: disposeBag)
    coordinate(to: get).subscribe().disposed(by: disposeBag)

    viewController.controllers = [getViewController!, spendViewController!]
    rootController.presentCard(viewController, animated: true)

    return viewModel.output.viewDidDisappear
  }

}
