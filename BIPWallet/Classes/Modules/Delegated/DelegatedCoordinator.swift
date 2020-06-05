//
//  DelegatedCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 10/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class DelegatedCoordinator: BaseCoordinator<Void> {

  let rootViewController: UINavigationController
  let balanceService: BalanceService
  let validatorService = ExplorerValidatorService()

  init(rootViewController: UINavigationController, balanceService: BalanceService) {
    self.rootViewController = rootViewController
    self.balanceService = balanceService

    validatorService.updateValidators()

    super.init()
  }

  override func start() -> Observable<Void> {
    let dependency = DelegatedViewModel.Dependency(balanceService: balanceService)
    let viewModel = DelegatedViewModel(dependency: dependency)

    let controller = DelegatedViewController.initFromStoryboard(name: "Delegated")
    controller.viewModel = viewModel

    viewModel.output.showUnbond.filter({ (val) -> Bool in
      return val.0 != nil && val.1 != nil
    }).flatMap({ [weak self] (val) -> Observable<Void> in
      guard let `self` = self, let presentVC = controller.tabBarController else { return Observable.empty() }
      return self.showUnbond(validator: val.0!, coin: val.1!, maxUnbondAmounts: val.2, rootViewController: presentVC)
    }).subscribe().disposed(by: disposeBag)

    viewModel.output.showDelegate.flatMap({ [weak self] (val) -> Observable<Void> in
      guard let `self` = self, let presentVC = controller.tabBarController else { return Observable.empty() }
      return self.showDelegate(validator: val, rootViewController: presentVC)
    }).subscribe().disposed(by: disposeBag)

    self.rootViewController.pushViewController(controller, animated: true)

    return Observable.never()
  }

  func showUnbond(validator: ValidatorItem? = nil, coin: String, maxUnbondAmounts: [String: Decimal]? = nil, rootViewController: UIViewController) -> Observable<Void> {
    let coordinator = DelegateUnbondCoordinator(rootViewController: rootViewController,
                                                balanceService: self.balanceService,
                                                validatorService: self.validatorService)
    coordinator.validatorItem = validator
    coordinator.isUnbond = true
    coordinator.coin = coin
    coordinator.maxUnbondAmounts = maxUnbondAmounts
    return coordinate(to: coordinator)
  }

  func showDelegate(validator: ValidatorItem? = nil, rootViewController: UIViewController) -> Observable<Void> {
    let coordinator = DelegateUnbondCoordinator(rootViewController: rootViewController,
                                                balanceService: self.balanceService,
                                                validatorService: self.validatorService)
    coordinator.validatorItem = validator
    return coordinate(to: coordinator)
  }
}
