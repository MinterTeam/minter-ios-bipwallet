//
//  BalanceCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import MinterExplorer

class BalanceCoordinator: BaseCoordinator<Void> {

  //Subject which is triggeren when valid Address or Public key was scaned
  var didScanRecipient = PublishSubject<String?>()

  private let navigationController: UINavigationController

  let authService: AuthService
  let balanceService: BalanceService
  let recipientInfoService: RecipientInfoService
  let transactionService: TransactionService
  let validatorService: ValidatorService
  let coinService: CoinService

  init(navigationController: UINavigationController,
       balanceService: BalanceService,
       authService: AuthService,
       recipientInfoService: RecipientInfoService,
       transactionService: TransactionService,
       validatorService: ValidatorService,
       coinService: CoinService
  ) {

    self.navigationController = navigationController
    self.balanceService = balanceService
    self.authService = authService
    self.recipientInfoService = recipientInfoService
    self.transactionService = transactionService
    self.validatorService = validatorService
    self.coinService = coinService

    validatorService.updateValidators()

    super.init()
  }

  override func start() -> Observable<Void> {
    let controller = BalanceViewController.initFromStoryboard(name: "Balance")
    let dependency = BalanceViewModel.Dependency(balanceService: balanceService,
                                                 appSettingsSerivce: LocalStorageAppSettings(),
                                                 coinService: coinService)
    let viewModel = BalanceViewModel(dependency: dependency)
    controller.viewModel = viewModel

    viewModel.output.didTapShare
      .withLatestFrom(balanceService.account).filter{$0 != nil}.map{$0!}
      .flatMap{ [unowned self] account in self.showShare(in: controller, account: account) }
      .subscribe()
      .disposed(by: disposeBag)

    var transactionsViewController: UIViewController?

    let coins = CoinsCoordinator(balanceService: balanceService, authService: authService)
    let transactions = TransactionsCoordinator(viewController: &transactionsViewController,
                                               balanceService: balanceService,
                                               recipientInfoService: recipientInfoService)

    coordinate(to: coins).subscribe().disposed(by: disposeBag)
    coordinate(to: transactions).subscribe().disposed(by: disposeBag)

    controller.controllers = [coins.viewController!, transactionsViewController!]

    let headerInset = CGFloat(230.0)

    viewModel.output.showDelegated.flatMap { [weak self] (_) -> Observable<Void> in
      guard let `self` = self else { return Observable.just(()) }
      return self.showDelegated(inViewController: self.navigationController, balanceService: self.balanceService)
    }.subscribe().disposed(by: disposeBag)

    viewModel.output.didScanQR.flatMap { (val) -> Observable<Void> in
      if let item = ValidatorItem(publicKey: val ?? ""), let root = controller.tabBarController {
        return self.showDelegateUnbond(rootViewController: root, validatorItem: item)
      }
      guard let url = URL(string: val ?? "") else {
        return Observable.empty()
      }
      return self.showRawTransaction(rootViewController: controller, url: url)
    }.subscribe().disposed(by: disposeBag)

    viewModel.output.didScanQR.filter({ (str) -> Bool in
      return (str?.isValidAddress() ?? false)
    }).subscribe(didScanRecipient).disposed(by: disposeBag)

    coins.didTapExchangeButton.flatMap({ [weak self] (_) -> Observable<Void> in
      guard let `self` = self else { return Observable.empty() }
      let excangeCoordinator = ExchangeCoordinator(rootController: controller,
                                                   balanceService: self.balanceService,
                                                   transactionService: self.transactionService,
                                                   coinService: self.coinService)
      return self.coordinate(to: excangeCoordinator)
    }).subscribe().disposed(by: self.disposeBag)

    self.bindSelectWallet(with: controller, viewModel: viewModel)

    //Updating emoji
    Observable.combineLatest(self.balanceService.balances(), self.balanceService.delegatedBalance()).withLatestFrom(self.balanceService.account) {
      return ($1, $0)
    }.filter({ (val) -> Bool in
      guard let address = val.0?.address else { return false }
      return val.1.0.address == address && val.1.1.0 == address
    }).flatMap({ (val) -> Observable<Void> in
      guard let account = val.0 else { return Observable.empty() }
      let balance = val.1.0
      let delegated = val.1.1
      account.emoji = AccountItem.emoji(for: balance.totalMainCoinBalance + (delegated.2 ?? 0.0))
      //Updating account emoji on getting newest balance data
      return self.authService.updateAccount(account: account)
    }).subscribe().disposed(by: disposeBag)
    
    viewModel.didRefresh.withLatestFrom(self.balanceService.account).subscribe(onNext: { (account) in
      guard let address = account?.address, address.isValidAddress() else { return }
      self.balanceService.updateBalance()
      self.balanceService.updateDelegated()
      transactions.refresh()
    }).disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}

extension BalanceCoordinator {

  func showDelegateUnbond(rootViewController: UIViewController, validatorItem: ValidatorItem) -> Observable<Void> {
    let coordiantor = DelegateUnbondCoordinator(rootViewController: rootViewController,
                                                balanceService: self.balanceService,
                                                validatorService: self.validatorService,
                                                coinService: coinService)
    coordiantor.validatorItem = validatorItem
    return coordinate(to: coordiantor)
  }

  func showDelegated(inViewController: UINavigationController, balanceService: BalanceService) -> Observable<Void> {
    let delegatedCoordinator = DelegatedCoordinator(rootViewController: inViewController,
                                                    balanceService: balanceService,
                                                    validatorService: self.validatorService,
                                                    coinService: self.coinService)
    return coordinate(to: delegatedCoordinator)
  }

  //Showing Select Wallet
  func showSelectWallet(rootViewController: UIViewController) -> Observable<SelectWalletCoordinationResult> {
    let selectWalletCoordinator = SelectWalletCoordinator(rootViewController: rootViewController,
                                                          authService: authService)
    return coordinate(to: selectWalletCoordinator)
  }

  //Showing Add Wallet
  func showAddWallet(inViewController: UIViewController) -> Observable<AddWalletCoordinatorResult> {
    let addWalletCoordinator = AddWalletCoordinator(rootViewController: inViewController,
                                                    authService: authService)
    return coordinate(to: addWalletCoordinator)
  }

  //Showing Edit Title
  func showEditTitle(inViewController: UIViewController, account: AccountItem) -> Observable<EditWalletTitleCoordinatorResult> {
    let editTitleCoordinator = EditWalletTitleCoordinator(rootViewController: inViewController, authService: self.authService, account: account)
    return coordinate(to: editTitleCoordinator)
  }

  func showShare(in viewController: UIViewController, account: AccountItem) -> Observable<Void> {
    let coordinator = ShareCoordinator(rootViewController: viewController, account: account)
    return coordinate(to: coordinator)
  }

  func showRawTransaction(rootViewController: UIViewController, url: URL) -> Observable<Void> {
    let coordinator = RawTransactionCoordinator(rootViewController: rootViewController,
                                                url: url,
                                                balanceService: self.balanceService,
                                                transactionService: self.transactionService,
                                                coinService: self.coinService)
    return coordinate(to: coordinator)
  }

  func bindSelectWallet(with controller: UIViewController, viewModel: WalletSelectableViewModel) {
    //Showing select wallet
    let selectWalletObservable = viewModel.showWalletObservable().flatMap({ [weak self] (_) -> Observable<SelectWalletCoordinationResult> in
      guard let `self` = self else { return Observable.empty() }
      return self.showSelectWallet(rootViewController: controller)
    }).do(onNext: { [weak self] (result) in
      switch result {
      case .wallet(let address):
        guard address.isValidAddress() else { return }
        try? self?.balanceService.changeAddress(address)
      default:
        return
      }
    }).share()
    
    selectWalletObservable.filter {
      switch $0 {
      case .wallet(_):
        return true
      default:
        return false
      }
    }.flatMap { (result) -> Observable<Event<Void>> in
      switch result {
      case .wallet(let address):
        return self.authService.selectAccount(address: address).materialize()

      default:
        return Observable.empty()
      }
    }.subscribe().disposed(by: disposeBag)

    //Showing Add Wallet
    selectWalletObservable
      .filter({ (result) -> Bool in
        switch result {
        case .addWallet:
          return true
        default:
          return false
        }
      }).flatMap({ (_) -> Observable<AddWalletCoordinatorResult> in
        return self.showAddWallet(inViewController: controller)
      }).subscribe(onNext: { (result) in
        switch result {
        case .added(let account):
          //switch to account
          try? self.balanceService.changeAddress(account.address)
        case .cancel:
          break
        }
      }).disposed(by: disposeBag)

    //Showing Wallet Title Edit
    selectWalletObservable
      .filter({ (result) -> Bool in
        switch result {
        case .edit(_):
          return true
        default:
          return false
        }
      }).map({ (result) -> AccountItem? in
        switch result {
        case .edit(let account):
          return account
        default:
          return nil
        }
      }).map{ $0! }
      .flatMap({ (account) -> Observable<EditWalletTitleCoordinatorResult> in
        return self.showEditTitle(inViewController: controller, account: account)
      }).subscribe(onNext: { [weak self] (result) in
        switch result {
        case .changedTitle(_):
          //Change address to itself to update UI
          if let address = self?.authService.selectedAccount()?.address {
            try? self?.balanceService.changeAddress(address)
          }
        case .cancel:
          return
        case .removed:
          if let selected = self?.authService.selectedAccount() {
            try? self?.balanceService.changeAddress(selected.address)
          }
        }
      }).disposed(by: disposeBag)

  }

}
