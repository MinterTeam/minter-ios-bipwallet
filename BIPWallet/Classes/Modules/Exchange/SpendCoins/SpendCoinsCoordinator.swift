//
//  SpendCoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SpendCoinsCoordinator: BaseCoordinator<Void> {

  private var сontroller = SpendCoinsViewController.initFromStoryboard(name: "Convert")
  private var convertPopupCoordiantor: ConvertPopupCoordinator?

  init(viewController: inout UIViewController?, balanceService: BalanceService, gateService: GateService, transactionService: TransactionService) {
    super.init()

    let dependency = SpendCoinsViewModel.Dependency(coinService: ExplorerCoinService(),
                                                    balanceService: balanceService,
                                                    gateService: gateService,
                                                    transactionService: transactionService)

    let viewModel = SpendCoinsViewModel(dependency: dependency)
    viewController = сontroller
    (viewController as? SpendCoinsViewController)?.viewModel = viewModel

    viewModel.output.showConfirmation.flatMap({ [weak self] (val) -> Observable<ConvertPopupCoordinatorResult> in
      guard let `self` = self else { return Observable.empty() }

      self.convertPopupCoordiantor = ConvertPopupCoordinator(rootViewController: self.сontroller, fromText: val.0, toText: val.1)

      guard let convertPopupCoordiantor = self.convertPopupCoordiantor else { return Observable.empty() }

      return self.coordinate(to: convertPopupCoordiantor)
    }).subscribe(onNext: { val in
      switch val {
      case .confirmed:
        viewModel.exchange()
        break

      case .canceled: break
        //do smth else
      }
    }).disposed(by: disposeBag)

    viewModel.exchangeSucceeded.flatMap({ [weak self] (val) -> Observable<Void> in
      guard let `self` = self, let convertPopupCoordiantor = self.convertPopupCoordiantor else { return Observable.empty() }
      return convertPopupCoordiantor.showSucceed(val.0, hash: val.1)
    }).subscribe().disposed(by: disposeBag)

    viewModel.errorNotification.subscribe(onNext: { [weak self] (message) in
      self?.convertPopupCoordiantor?.close()
    }).disposed(by: disposeBag)
  }

  override func start() -> Observable<Void> {
    return сontroller.rx.deallocated
  }

}
