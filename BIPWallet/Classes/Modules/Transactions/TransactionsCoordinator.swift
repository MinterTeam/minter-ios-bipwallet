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
  private let balanceService: BalanceService
  private let recipientInfoService: RecipientInfoService

  init(viewController: inout UIViewController?,
       balanceService: BalanceService,
       recipientInfoService: RecipientInfoService) {

    self.balanceService = balanceService
    self.recipientInfoService = recipientInfoService

    super.init()

    viewController = self.сontroller
  }

  override func start() -> Observable<Void> {

    let transactionService = ExplorerTransactionService()
    let dependency = TransactionsViewModel.Dependency(transactionService: transactionService,
                                                      balanceService: balanceService,
                                                      infoService: self.recipientInfoService)
    let viewModel = TransactionsViewModel(dependency: dependency)

    viewModel.output.showTransaction.withLatestFrom(self.balanceService.account) { ($0, $1) }.flatMap({ [weak self] (val) -> Observable<Void> in
      guard let `self` = self, let transaction = val.0, let address = val.1?.address else { return Observable.empty() }
      let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                          address: address,
                                                          rootViewController: self.сontroller,
                                                          recipientInfoService: self.recipientInfoService)
      return self.coordinate(to: transactionCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    viewModel.output.showAllTransactions.flatMap { (_) -> Observable<Void> in
      guard let navigationController = self.сontroller.navigationController else { return Observable.empty() }
      return self.showAllTransactions(navigationController: navigationController,
                                      recipientInfoService: self.recipientInfoService)
    }.subscribe().disposed(by: disposeBag)

    сontroller.viewModel = viewModel

    return сontroller.rx.deallocated
  }

  func showAllTransactions(navigationController: UINavigationController, recipientInfoService: RecipientInfoService) -> Observable<Void> {
    let coordinator = AllTransactionsCoordinator(navigationController: navigationController, balanceService: self.balanceService, recipientInfoService: recipientInfoService)
    return coordinate(to: coordinator)
  }

  func refresh() {
    сontroller.viewModel?.input.didRefresh.onNext(())
  }

}
