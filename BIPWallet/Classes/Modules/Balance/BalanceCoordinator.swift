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

  let authService: AuthService
  let balanceService: BalanceService

  init(navigationController: UINavigationController, balanceService: BalanceService, authService: AuthService) {
    self.navigationController = navigationController
    self.balanceService = balanceService
    self.authService = authService

    super.init()
  }

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

    coins.didScrollToPoint?.subscribe(onNext: { [weak self] (point) in
      if controller.segmentedControl?.selectedSegmentIndex == 0 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint?.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        if let transactionsViewController = transactionsViewController as? TransactionsViewController {
          transactionsViewController.tableView?.setContentOffset(contentOffset, animated: false)
        }
      }
    }).disposed(by: disposeBag)

    coins
      .didTapExchangeButton
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [weak self] (_) in
        guard let `self` = self else { return }
        let excangeCoordinator = ExchangeCoordinator(rootController: controller,
                                                     balanceService: self.balanceService)
        self.coordinate(to: excangeCoordinator).subscribe().disposed(by: self.disposeBag)
    }).disposed(by: disposeBag)

    transactions.didScrollToPoint?.subscribe(onNext: { (point) in
      if controller.segmentedControl.selectedSegmentIndex == 1 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        coins.viewController?.tableView?.setContentOffset(contentOffset, animated: false)
      }
    }).disposed(by: disposeBag)

    balanceService.updateBalance()

    viewModel.output.didTapSelectWallet.flatMap({ (_) -> Observable<SelectWalletCoordinationResult> in
      return self.showSelectWallet(rootViewController: controller)
    }).do(onNext: { [weak self] (result) in
      switch result {
      case .wallet(let address):
        guard address.isValidAddress() else { return }
        try? self?.balanceService.changeAddress(address)
      case .cancel:
        return
      case .addWallet:
        return
      }
    }).filter({ (result) -> Bool in
      switch result {
      case .addWallet:
        return true
      default:
        return false
      }
    }).flatMap({ (_) -> Observable<Void> in
      return self.showAddWallet(inViewController: controller)
    }).subscribe().disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

  func showSelectWallet(rootViewController: UIViewController) -> Observable<SelectWalletCoordinationResult> {
    let selectWalletCoordinator = SelectWalletCoordinator(rootViewController: rootViewController,
                                                          authService: authService)
    return coordinate(to: selectWalletCoordinator)
  }

  func showAddWallet(inViewController: UIViewController) -> Observable<Void> {
    let createWalletCoordinator = CreateWalletCoordinator(rootViewController: inViewController,
                                                          authService: self.authService)
    return self.coordinate(to: createWalletCoordinator)
  }

}
