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

    viewModel.output.showTransaction.withLatestFrom(self.balanceService.account) { ($0, $1) }.flatMap({ [weak self] (val) -> Observable<Void> in
      guard let `self` = self, let transaction = val.0, let address = val.1?.address else { return Observable.empty() }
      let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                          address: address,
                                                          rootViewController: сontroller,
                                                          recipientInfoService: self.recipientInfoService)
      return self.coordinate(to: transactionCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    сontroller.viewModel = viewModel
    navigationController.pushViewController(сontroller, animated: true)

    return сontroller.rx.viewDidDisappear.map { _ in Void() }
  }
}
