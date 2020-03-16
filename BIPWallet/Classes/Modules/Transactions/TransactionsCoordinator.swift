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

  init(viewController: inout UIViewController?) {
    super.init()

    viewController = self.сontroller
  }

  var didScrollToPoint: Observable<CGPoint>?

  override func start() -> Observable<Void> {
    let localAuthService = LocalStorageAuthService()
    if let account = localAuthService.selectedAccount() {

      let transactionService = ExplorerTransactionService()

      let viewModel = TransactionsViewModel(address: account.address,
                                            dependency: TransactionsViewModel.Dependency(transactionService: transactionService))

      viewModel.output.showTransaction.subscribe(onNext: { [weak self] (transaction) in
        guard let `self` = self else { return }
        let transactionCoordinator = TransactionCoordinator(transaction: transaction,
                                                            rootViewController: self.сontroller)
        self.coordinate(to: transactionCoordinator).subscribe().disposed(by: self.disposeBag)
      }).disposed(by: disposeBag)

      сontroller.viewModel = viewModel

      self.didScrollToPoint = сontroller.rx.viewDidLoad.flatMap({ [weak self] (_) -> Observable<CGPoint> in
        guard let `self` = self else { return Observable.empty() }
        return self.сontroller.tableView.rx.didScroll.map { (_) -> CGPoint in
          return self.сontroller.tableView.contentOffset
        }
      })
    }

    return Observable.never()
  }

}
