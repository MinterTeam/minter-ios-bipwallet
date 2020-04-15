//
//  TransactionsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import MinterExplorer
import RxAppState

class TransactionsCoordinator: BaseCoordinator<Void> {

  private var сontroller = TransactionsViewController.initFromStoryboard(name: "Transactions")
  var balanceService: BalanceService

  init(viewController: inout UIViewController?, balanceService: BalanceService) {
    self.balanceService = balanceService

    super.init()

    viewController = self.сontroller
  }

  var didScrollToPoint: Observable<CGPoint>?

  override func start() -> Observable<Void> {

    let transactionService = ExplorerTransactionService()
    let dependency = TransactionsViewModel.Dependency(transactionService: transactionService,
                                                      balanceService: balanceService)
    let viewModel = TransactionsViewModel(dependency: dependency)

    viewModel.output.showTransaction.flatMap({ [weak self] (transaction) -> Observable<Void> in
      guard let `self` = self, let transaction = transaction else { return Observable.empty() }
      let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                          rootViewController: self.сontroller)
      return self.coordinate(to: transactionCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    viewModel.output.showAllTransactions.flatMap { (_) -> Observable<Void> in
      guard let navigationController = self.сontroller.navigationController else { return Observable.empty() }
      return self.showAllTransactions(navigationController: navigationController)
    }.subscribe().disposed(by: disposeBag)

    сontroller.viewModel = viewModel

    self.didScrollToPoint = сontroller.rx.viewDidLoad.flatMap({ [weak self] (_) -> Observable<CGPoint> in
      guard let `self` = self else { return Observable.empty() }
      return self.сontroller.tableView.rx.didScroll.map { (_) -> CGPoint in
        return self.сontroller.tableView.contentOffset
      }
    })
    return Observable.never()
  }

  func showAllTransactions(navigationController: UINavigationController) -> Observable<Void> {
    let coordinator = AllTransactionsCoordinator(navigationController: navigationController, balanceService: self.balanceService)
    return coordinate(to: coordinator)
  }

}
