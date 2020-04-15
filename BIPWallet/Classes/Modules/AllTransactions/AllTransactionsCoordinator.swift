//
//  AllTransactionsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class AllTransactionsCoordinator: BaseCoordinator<Void> {

  var balanceService: BalanceService
  var navigationController: UINavigationController

  init(navigationController: UINavigationController, balanceService: BalanceService) {
    self.balanceService = balanceService
    self.navigationController = navigationController

    super.init()
  }

  var didScrollToPoint: Observable<CGPoint>?

  override func start() -> Observable<Void> {
    var сontroller = AllTransactionsViewController.initFromStoryboard(name: "AllTransactions")

    let transactionService = ExplorerTransactionService()
    let dependency = AllTransactionsViewModel.Dependency(transactionService: transactionService,
                                                         balanceService: balanceService)
    let viewModel = AllTransactionsViewModel(dependency: dependency)

    viewModel.output.showTransaction.flatMap({ [weak self] (transaction) -> Observable<Void> in
      guard let `self` = self, let transaction = transaction else { return Observable.empty() }
      let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                          rootViewController: сontroller)
      return self.coordinate(to: transactionCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    сontroller.viewModel = viewModel
    navigationController.pushViewController(сontroller, animated: true)

    return сontroller.rx.viewDidDisappear.map { _ in Void() }
  }
}
