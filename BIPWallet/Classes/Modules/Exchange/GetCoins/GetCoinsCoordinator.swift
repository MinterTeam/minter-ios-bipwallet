//
//  GetCoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class GetCoinsCoordinator: BaseCoordinator<Void> {

  private var сontroller = GetCoinsViewController.initFromStoryboard(name: "Convert")
  private let balanceService: BalanceService

  init(viewController: inout UIViewController?, balanceService: BalanceService, gateService: GateService) {
    self.balanceService = balanceService
    let viewModel = GetCoinsViewModel(dependency: GetCoinsViewModel.Dependency(balanceService: balanceService,
                                                                               coinService: ExplorerCoinService(),
                                                                               gateService: gateService))
    viewController = сontroller
    (viewController as? GetCoinsViewController)?.viewModel = viewModel
  }

  override func start() -> Observable<Void> {
    return Observable.never()
  }

}
