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

  let balanceService: BalanceService
  let recipientInfoService: RecipientInfoService
  var navigationController: UINavigationController

  init(navigationController: UINavigationController, balanceService: BalanceService, recipientInfoService: RecipientInfoService) {
    self.balanceService = balanceService
    self.recipientInfoService = recipientInfoService
    self.navigationController = navigationController

    super.init()
  }

  var didScrollToPoint: Observable<CGPoint>?

  override func start() -> Observable<Void> {
    let сontroller = AllTransactionsViewController.initFromStoryboard(name: "AllTransactions")

    let transactionService = ExplorerTransactionService()
    let dependency = AllTransactionsViewModel.Dependency(transactionService: transactionService,
                                                         balanceService: balanceService,
                                                         recipientInfoService: recipientInfoService)
    let viewModel = AllTransactionsViewModel(dependency: dependency)

    viewModel.output.showTransaction.flatMap({ [weak self] (transaction) -> Observable<Void> in
      guard let `self` = self, let transaction = transaction else { return Observable.empty() }
      let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                          rootViewController: сontroller,
                                                          recipientInfoService: self.recipientInfoService)
      return self.coordinate(to: transactionCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    сontroller.viewModel = viewModel
    navigationController.pushViewController(сontroller, animated: true)

    return сontroller.rx.viewDidDisappear.map { _ in Void() }
  }
}
