//
//  GetCoinsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class GetCoinsCoordinator: BaseCoordinator<Void> {

  private var сontroller = GetCoinsViewController.initFromStoryboard(name: "Convert")
  private let balanceService: BalanceService
  private var convertPopupCoordiantor: ConvertPopupCoordinator?

  init(viewController: inout UIViewController?, balanceService: BalanceService, gateService: GateService, transactionService: TransactionService) {
    self.balanceService = balanceService
    super.init()

    let viewModel = GetCoinsViewModel(dependency: GetCoinsViewModel.Dependency(balanceService: balanceService,
                                                                               coinService: ExplorerCoinService(),
                                                                               gateService: gateService,
                                                                               transactionService: transactionService))
    viewController = сontroller
    (viewController as? GetCoinsViewController)?.viewModel = viewModel

    viewModel.output.showConfirmation.flatMap({ [weak self] (val) -> Observable<ConvertPopupCoordinatorResult> in
      guard let `self` = self else { return Observable.empty() }
      self.convertPopupCoordiantor = ConvertPopupCoordinator(rootViewController: self.сontroller, fromText: val.0, toText: val.1)

      guard let convertPopupCoordiantor = self.convertPopupCoordiantor else { return Observable.empty() }

      return self.coordinate(to: convertPopupCoordiantor)
    }).withLatestFrom(balanceService.account) {
      return ($0, $1)
    }.subscribe(onNext: { val in
      guard let address = val.1?.address else { return }

      switch val.0 {
      case .confirmed:
        viewModel.exchange(selectedAddress: address)
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
