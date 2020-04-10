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
    let dependency = BalanceViewModel.Dependency(balanceService: balanceService)
    let viewModel = BalanceViewModel(dependency: dependency)
    controller.viewModel = viewModel

    var transactionsViewController: UIViewController?

    let coins = CoinsCoordinator(balanceService: balanceService)
    let transactions = TransactionsCoordinator(viewController: &transactionsViewController,
                                               balanceService: balanceService)

    coordinate(to: coins).subscribe().disposed(by: disposeBag)
    coordinate(to: transactions).subscribe().disposed(by: disposeBag)

    controller.controllers = [coins.viewController!, transactionsViewController!]

    let headerInset = CGFloat(230.0)

    coins.didScrollToPoint?.subscribe(onNext: { (point) in
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
      .flatMap({ [weak self] (_) -> Observable<Void> in
        guard let `self` = self else { return Observable.just(()) }
        let excangeCoordinator = ExchangeCoordinator(rootController: controller,
                                                     balanceService: self.balanceService)
        return self.coordinate(to: excangeCoordinator)
      }).subscribe().disposed(by: self.disposeBag)

    transactions.didScrollToPoint?.subscribe(onNext: { (point) in
      if controller.segmentedControl.selectedSegmentIndex == 1 {
        let newPoint = headerInset + point.y
        controller.containerViewHeightConstraint.constant = max(-headerInset, -newPoint)
        let contentOffset = CGPoint(x: 0, y: point.y)
        coins.viewController?.tableView?.setContentOffset(contentOffset, animated: false)
      }
    }).disposed(by: disposeBag)

    balanceService.updateBalance()

    let selectWalletObservable = viewModel.output.didTapSelectWallet.flatMap({ (_) -> Observable<SelectWalletCoordinationResult> in
      return self.showSelectWallet(rootViewController: controller)
    }).do(onNext: { [weak self] (result) in
      switch result {
      case .wallet(let address):
        guard address.isValidAddress() else { return }
        try? self?.balanceService.changeAddress(address)
      default:
        return
      }
    }).share()

    //Showing Add Wallet
    selectWalletObservable
      .filter({ (result) -> Bool in
        switch result {
        case .addWallet:
          return true
        default:
          return false
        }
      }).flatMap({ (_) -> Observable<AddWalletCoordinatorResult> in
        return self.showAddWallet(inViewController: controller)
      }).subscribe(onNext: { (result) in
        switch result {
        case .added(let account):
          //switch to account
          try? self.balanceService.changeAddress(account.address)
        case .cancel:
          break
        }
      }).disposed(by: disposeBag)

    //Showing Wallet Title Edit
    selectWalletObservable
      .filter({ (result) -> Bool in
        switch result {
        case .edit(let _):
          return true
        default:
          return false
        }
      }).map({ (result) -> AccountItem? in
        switch result {
        case .edit(let account):
          return account
        default:
          return nil
        }
      }).map{ $0! }
      .flatMap({ (account) -> Observable<EditWalletTitleCoordinatorResult> in
        return self.showEditTitle(inViewController: controller, account: account)
      }).subscribe(onNext: { [weak self] (result) in
        switch result{
        case .changedTitle(let account):
          try? self?.balanceService.changeAddress(account.address)
        case .cancel:
          return
        }
      }).disposed(by: disposeBag)

    balanceService.account.flatMap { [weak self] (item) -> Observable<Event<(AccountItem?, BalanceService.BalancesResponse)>> in
      guard let `self` = self, let address = item?.address else { return Observable.empty() }
      return Observable.zip(self.balanceService.account, self.balanceService.balances(address: address)).materialize()
    }.flatMap({ (event) -> Observable<Void> in
      switch event {
      case .next(let val):
        guard let account = val.0 else { return Observable.empty() }
        account.emoji = AccountItem.emoji(for: val.1.totalMainCoinBalance)
        //Updating account emoji on getting newest balance data
        return self.authService.updateAccount(account: account)
      case .completed:
        return Observable.empty()
      case .error(let _):
        return Observable.empty()
      }
    }).subscribe().disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

  //Showing Select Wallet
  func showSelectWallet(rootViewController: UIViewController) -> Observable<SelectWalletCoordinationResult> {
    let selectWalletCoordinator = SelectWalletCoordinator(rootViewController: rootViewController,
                                                          authService: authService)
    return coordinate(to: selectWalletCoordinator)
  }

  //Showing Add Wallet
  func showAddWallet(inViewController: UIViewController) -> Observable<AddWalletCoordinatorResult> {
    let addWalletCoordinator = AddWalletCoordinator(rootViewController: inViewController,
                                                    authService: authService)
    return self.coordinate(to: addWalletCoordinator)
  }
  
  //Showing Edit Title
  func showEditTitle(inViewController: UIViewController, account: AccountItem) -> Observable<EditWalletTitleCoordinatorResult> {
    let editTitleCoordinator = EditWalletTitleCoordinator(rootViewController: inViewController, authService: self.authService, account: account)
    return self.coordinate(to: editTitleCoordinator)
  }

}
