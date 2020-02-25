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

  var viewController: TransactionsViewController?

  var didScrollToPoint: Observable<CGPoint>?

//  var didChangeInset = PublishSubject<CGFloat>()

  override func start() -> Observable<Void> {
    let localAuthService = LocalStorageAuthService()
    if let account = localAuthService.selectedAccount() {

      let controller = TransactionsViewController.initFromStoryboard(name: "Transactions")

      let transactionService = ExplorerTransactionService()

      let viewModel = TransactionsViewModel(address: account.address,
                                            dependency: TransactionsViewModel.Dependency(transactionService: transactionService))

      controller.viewModel = viewModel
      viewController = controller

      self.didScrollToPoint = controller.rx.viewDidLoad.flatMap({ (_) -> Observable<CGPoint> in
        return controller.tableView.rx.didScroll.map { (_) -> CGPoint in
          return controller.tableView.contentOffset
        }
      })

//      didChangeInset.subscribe(onNext: { [weak controller] (val) in
//        controller?.tableView.contentOffset = CGPoint(x: 0, y: val)
//        //contentInset = UIEdgeInsets(top: val, left: 0, bottom: 0, right: 0)
//      }).disposed(by: disposeBag)
    }

    return Observable.never()
  }

}
