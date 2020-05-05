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
    let dependency = ExchangeViewModel.Dependency(balanceService: balanceService)
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

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 20.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

    //Seem to be a bug, but without "main.async" it delays
    DispatchQueue.main.async { [weak self] in
      self?.rootController.presentCard(viewController,
                                       configuration: cardConfig,
                                       animated: true)
    }

    return viewModel.output.viewDidDisappear
  }

}
