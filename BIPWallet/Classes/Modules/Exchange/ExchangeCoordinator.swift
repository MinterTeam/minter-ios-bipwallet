//
//  ExchangeCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

class ExchangeCoordinator: BaseCoordinator<Void> {

  struct Settings {
    var showBuy: Bool = false
    var buyCoin: String?
    var buyAmount: Decimal?
    var neededAmount: Decimal?
    var closeAfterTransaction: Bool = false
  }

  let rootController: UIViewController
  let balanceService: BalanceService
  let transactionService: TransactionService
  let coinService: CoinService
  private(set) var settings: Settings?

  init(rootController: UIViewController,
       balanceService: BalanceService,
       transactionService: TransactionService,
       coinService: CoinService,
       settings: Settings? = nil) {

    self.rootController = rootController
    self.balanceService = balanceService
    self.transactionService = transactionService
    self.coinService = coinService
    self.settings = settings
  }

  override func start() -> Observable<Void> {
    let dependency = ExchangeViewModel.Dependency(balanceService: balanceService)
    let viewModel = ExchangeViewModel(dependency: dependency)
    let viewController = ExchangeViewController.initFromStoryboard(name: "Exchange")
    viewController.viewModel = viewModel

    var getViewController: UIViewController?
    var spendViewController: UIViewController?

    let gateService = ExplorerGateService()
//    gateService.priceCommissions().subscribe().disposed(by: disposeBag)
    
    let poolService = ExplorerPoolService()

    let spend = SpendCoinsCoordinator(viewController: &spendViewController,
                                      balanceService: balanceService,
                                      gateService: gateService,
                                      transactionService: transactionService,
                                      coinService: coinService,
                                      poolService: poolService
                                      )

    let get = GetCoinsCoordinator(viewController: &getViewController,
                                  balanceService: balanceService,
                                  gateService: gateService,
                                  transactionService: transactionService,
                                  coinService: coinService,
                                  poolService: poolService,
                                  coin: settings?.buyCoin,
                                  amount: settings?.buyAmount,
                                  closeAfterBuy: settings?.closeAfterTransaction ?? false)

    if settings?.closeAfterTransaction == true {
      get.exchnaged.withLatestFrom(dependency.balanceService.balances()).subscribe(onNext: { [weak self] (balances) in
        guard let coin = self?.settings?.buyCoin,
          let amount = self?.settings?.neededAmount,
          (balances.balances[coin]?.0 ?? 0.0) >= amount else {
            return
        }
        viewController.dismiss(animated: true, completion: nil)
      }).disposed(by: disposeBag)
    }

    coordinate(to: spend).subscribe().disposed(by: disposeBag)
    coordinate(to: get).subscribe().disposed(by: disposeBag)

    viewController.controllers = [spendViewController!, getViewController!]

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 20.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

    //Seem to be a bug, but without "main.async" it delays
    DispatchQueue.main.async { [weak self] in
      self?.rootController.presentCard(viewController,
                                       configuration: cardConfig,
                                       animated: true, completion: {
                                        if self?.settings?.showBuy ?? false {
                                          viewController.moveToViewController(at: 1)
                                        }
      })
    }
    return viewController.rx.deallocated
  }

}
