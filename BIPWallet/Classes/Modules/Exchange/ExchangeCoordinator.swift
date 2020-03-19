//
//  ExchangeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class ExchangeCoordinator: BaseCoordinator<Void> {

  let rootController: UIViewController

  init(rootController: UIViewController) {
    self.rootController = rootController
  }

  override func start() -> Observable<Void> {
    let dependency = ExchangeViewModel.Dependency()
    let viewModel = ExchangeViewModel(dependency: dependency)
    let viewController = ExchangeViewController.initFromStoryboard(name: "Exchange")
    viewController.viewModel = viewModel

    var getViewController: UIViewController?
    var spendViewController: UIViewController?

    let spend = SpendCoinsCoordinator(viewController: &spendViewController)
    let get = GetCoinsCoordinator(viewController: &getViewController)

    coordinate(to: spend).subscribe().disposed(by: disposeBag)
    coordinate(to: get).subscribe().disposed(by: disposeBag)

    viewController.controllers = [getViewController!, spendViewController!]

    rootController.presentCard(viewController, animated: true)

    return Observable.never()
  }

}
