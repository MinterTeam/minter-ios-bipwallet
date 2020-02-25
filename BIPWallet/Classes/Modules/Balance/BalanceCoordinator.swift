//
//  BalanceCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import MinterExplorer

class BalanceCoordinator: BaseCoordinator<Void> {

  private let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController

    super.init()
  }

  override func start() -> Observable<Void> {
    let controller = BalanceViewController.initFromStoryboard(name: "Balance")
    let balanceService = ExplorerBalanceService()
    
    controller.viewModel = BalanceViewModel(dependency: BalanceViewModel.Dependency(balanceService: balanceService))

    let coins = CoinsCoordinator()
    let transactions = TransactionsCoordinator()

    coordinate(to: coins).subscribe().disposed(by: disposeBag)
    coordinate(to: transactions).subscribe().disposed(by: disposeBag)

    controller.controllers = [coins.viewController!, transactions.viewController!]

    let headerInset = CGFloat(230.0)

    coins.didScrollToPoint?.subscribe(onNext: { (point) in
      if controller.segmentedControl.selectedSegmentIndex == 0 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        transactions.viewController?.tableView?.setContentOffset(contentOffset, animated: false)
      }
    }).disposed(by: disposeBag)

    transactions.didScrollToPoint?.subscribe(onNext: { (point) in
      if controller.segmentedControl.selectedSegmentIndex == 1 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        coins.viewController?.tableView?.setContentOffset(contentOffset, animated: false)
      }
    }).disposed(by: disposeBag).self

//    let localAuthService = LocalStorageAuthService()
//    if let account = localAuthService.selectedAccount() {
//      balanceService.balances(address: "Mx" + account.address)
//        .subscribe(onNext: { [weak self] (val) in
//        self?.coinsSubject.onNext(val.balances)
//      }).disposed(by: disposeBag)
//    }

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}
