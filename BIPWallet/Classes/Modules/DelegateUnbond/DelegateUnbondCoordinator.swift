//
//  DelegateUnbondCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class DelegateUnbondCoordinator: BaseCoordinator<Void> {

  let rootViewController: UIViewController
  let balanceService: BalanceService
  var validatorItem: ValidatorItem?
  var isUnbond = false
  var maxUnbondAmount: Decimal?
  var coin: String?

  init(rootViewController: UIViewController, balanceService: BalanceService) {
    self.rootViewController = rootViewController
    self.balanceService = balanceService
  }

  override func start() -> Observable<Void> {
    let validatorService = ExplorerValidatorService()
    validatorService.updateValidators()
    let accountService = LocalStorageAccountService()

    let gateService = ExplorerGateService()
    
    gateService.updateGas()

    let dependency = DelegateUnbondViewModel.Dependency(validatorService: validatorService,
                                                        balanceService: balanceService,
                                                        gateService: gateService,
                                                        accountService: accountService)

    let viewModel = DelegateUnbondViewModel(validator: validatorItem,
                                            coinName: coin,
                                            isUnbond: isUnbond,
                                            maxUnbondAmount: maxUnbondAmount,
                                            dependency: dependency)

    let controller = DelegateUnbondViewController.initFromStoryboard(name: "DelegateUnbond")
    controller.viewModel = viewModel

    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.present(controller, animated: true, completion: nil)

    return controller.rx.viewDidDisappear.map { _ in Void() }.take(1)
  }

}
