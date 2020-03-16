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

    let localAuthService = LocalStorageAuthService()
    let addressObservable = Observable.just("Mx" + (localAuthService.selectedAccount()?.address ?? ""))

    self.localAuthService = localAuthService
    self.balanceService = ExplorerBalanceService(address: addressObservable)

    super.init()
  }

  let localAuthService: LocalStorageAuthService
  let balanceService: ExplorerBalanceService

  override func start() -> Observable<Void> {
    let controller = BalanceViewController.initFromStoryboard(name: "Balance")
    let viewModel = BalanceViewModel(dependency: BalanceViewModel.Dependency(balanceService: balanceService))
    controller.viewModel = viewModel

    var transactionsViewController: UIViewController?
    
    let coins = CoinsCoordinator(balanceService: balanceService)
    let transactions = TransactionsCoordinator(viewController: &transactionsViewController)

    coordinate(to: coins).subscribe().disposed(by: disposeBag)
    coordinate(to: transactions).subscribe().disposed(by: disposeBag)

    controller.controllers = [coins.viewController!, transactionsViewController!]

    let headerInset = CGFloat(230.0)

    coins.didScrollToPoint?.subscribe(onNext: { (point) in
      if controller.segmentedControl.selectedSegmentIndex == 0 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        if let transactionsViewController = transactionsViewController as? TransactionsViewController {
          transactionsViewController.tableView.setContentOffset(contentOffset, animated: false)
        }
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

    balanceService.updateBalance()

    viewModel.output.didTapSelectWallet.flatMap({ (_) -> Observable<SelectWalletCoordinationResult> in
      return self.showSelectWallet(rootViewController: controller)
    }).subscribe().disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

  func showSelectWallet(rootViewController: UIViewController) -> Observable<SelectWalletCoordinationResult> {
    let selectWalletCoordinator = SelectWalletCoordinator(rootViewController: rootViewController, authService: localAuthService)
    return coordinate(to: selectWalletCoordinator)
  }

}
