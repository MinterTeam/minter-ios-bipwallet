//
//  SendCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices

class SendCoordinator: BaseCoordinator<Void> {

  var recipient = PublishSubject<String?>()

  private let navigationController: UINavigationController

  let authService: AuthService
  let balanceService: BalanceService
  let contactsService: ContactsService
  let recipientInfoService: RecipientInfoService
  let validatorService: ValidatorService
  let coinService: CoinService

  init(navigationController: UINavigationController,
       balanceService: BalanceService,
       authService: AuthService,
       contactsService: ContactsService,
       recipientInfoService: RecipientInfoService,
       validatorService: ValidatorService,
       coinService: CoinService
  ) {

    self.navigationController = navigationController
    self.authService = authService
    self.balanceService = balanceService
    self.contactsService = contactsService
    self.recipientInfoService = recipientInfoService
    self.validatorService = validatorService
    self.coinService = coinService

    super.init()

    balanceService.updateBalance()
  }

  override func start() -> Observable<Void> {
    let controller = SendViewController.initFromStoryboard(name: "Send")
    let dependency = SendViewModel.Dependency(balanceService: balanceService,
                                              contactsService: contactsService,
                                              recipientInfoService: recipientInfoService,
                                              coinService: coinService
    )
    let viewModel = SendViewModel(dependency: dependency)
    controller.viewModel = viewModel

    viewModel.output.showContactsPicker
      .flatMap { [weak self] (_) -> Observable<ContactItem?> in
        guard let `self` = self else { return Observable.empty() }
        return self.showContacts(rootViewController: controller)
      }.filter({ (item) -> Bool in
        return item != nil
      }).map({ (item) -> ContactItem in
        return item!
      }).subscribe(viewModel.input.contact).disposed(by: disposeBag)

    viewModel.output.showSendSucceed.flatMap { [weak self, weak controller] (val) -> Observable<SendSucceedPopupCoordinatorResult> in
      guard let `self` = self, let controller = controller else { return Observable.empty() }
      let shouldHideActionButton = val.1 != nil ? (self.recipientInfoService.title(for: val.1!) != nil) : false
      return self.showSendSucceed(rootViewController: controller,
                                  inPopupViewController: controller.popupViewController,
                                  recipient: val.0,
                                  address: val.1,
                                  shouldHideActionButton: shouldHideActionButton)

    }.delay(.milliseconds(1500), scheduler: MainScheduler.asyncInstance).flatMap({ [weak self] (val) -> Observable<Any> in
      guard let `self` = self, let tabbarViewController = controller.tabBarController else { return Observable.empty() }

      switch val {
      case .showAddAddress(let address):
        guard let address = address, address.isValidAddress() else { return Observable.empty() }
        return self.showAddContact(rootViewController: tabbarViewController, address: address).map {_ in}

      case .viewTransaction:
        guard let url = viewModel.lastTransactionExplorerURL() else { return Observable.empty() }
        let safari = SFSafariViewController(url: url)
        tabbarViewController.present(safari, animated: true) {}
        return safari.rx.deallocated.map {_ in ""}

      case .cancel:
        return Observable.empty()
      }
    }).subscribe().disposed(by: disposeBag)

    viewModel.output.didScanQR.flatMap { (val) -> Observable<Void> in
      if let item = ValidatorItem(publicKey: val ?? ""), let root = controller.tabBarController {
        return self.showDelegateUnbond(rootViewController: root, validatorItem: item)
      }
      return Observable.empty()
    }.subscribe().disposed(by: disposeBag)

    recipient.subscribe(viewModel.input.didScanQR).disposed(by: disposeBag)

    self.bindSelectWallet(with: controller, viewModel: viewModel)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}

extension SendCoordinator {

  func showDelegateUnbond(rootViewController: UIViewController, validatorItem: ValidatorItem) -> Observable<Void> {
    let coordiantor = DelegateUnbondCoordinator(rootViewController: rootViewController,
                                                balanceService: self.balanceService,
                                                validatorService: self.validatorService,
                                                coinService: self.coinService)
    coordiantor.validatorItem = validatorItem
    return coordinate(to: coordiantor)
  }

  func showAddContact(rootViewController: UIViewController, address: String) -> Observable<ContactItem?> {
    let coordinator = ModifyContactCoordinator(address: address, rootViewController: rootViewController, contactsService: contactsService)
    return coordinate(to: coordinator)
  }

  func showContacts(rootViewController: UIViewController) -> Observable<ContactItem?> {
    let contactsCoordinator = ContactPickerCoordinator(rootViewController: rootViewController, contactsService: contactsService)
    return coordinate(to: contactsCoordinator).map { (result) -> ContactItem? in
      switch result {
      case .contact(let item):
        return item
      case .cancel:
        return nil
      }
    }
  }

  func showSendSucceed(rootViewController: UIViewController,
                       inPopupViewController: PopupViewController?,
                       recipient: String?,
                       address: String?,
                       shouldHideActionButton: Bool) -> Observable<SendSucceedPopupCoordinatorResult> {

    let coordinator = SendSucceedPopupCoordinator(rootViewController: rootViewController,
                                                  inPopupViewController: inPopupViewController,
                                                  recipient: recipient,
                                                  address: address,
                                                  shouldHideActionButton: shouldHideActionButton)
    return coordinate(to: coordinator)
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

  func bindSelectWallet(with controller: UIViewController, viewModel: WalletSelectableViewModel) {
    //Showing select wallet
    let selectWalletObservable = viewModel.showWalletObservable().flatMap({ (_) -> Observable<SelectWalletCoordinationResult> in
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
      .flatMap({ [weak self] (account) -> Observable<EditWalletTitleCoordinatorResult> in
        guard let `self` = self else { return Observable.empty() }
        return self.showEditTitle(inViewController: controller, account: account)
      }).subscribe(onNext: { [weak self] (result) in
        switch result {
        case .changedTitle(_):
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
