//
//  SendCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendCoordinator: BaseCoordinator<Void> {

  var recipient = PublishSubject<String?>()

  private let navigationController: UINavigationController

  let authService: AuthService
  let balanceService: BalanceService
  let contactsService: ContactsService
  let recipientInfoService: RecipientInfoService

  init(navigationController: UINavigationController,
       balanceService: BalanceService,
       authService: AuthService,
       contactsService: ContactsService,
       recipientInfoService: RecipientInfoService) {

    self.navigationController = navigationController
    self.authService = authService
    self.balanceService = balanceService
    self.contactsService = contactsService
    self.recipientInfoService = recipientInfoService

    super.init()

    balanceService.updateBalance()
  }

  override func start() -> Observable<Void> {
    let controller = SendViewController.initFromStoryboard(name: "Send")
    let dependency = SendViewModel.Dependency(balanceService: balanceService,
                                              contactsService: contactsService,
                                              recipientInfoService: recipientInfoService
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

    recipient.subscribe(viewModel.input.didScanQR).disposed(by: disposeBag)

    self.bindSelectWallet(with: controller, viewModel: viewModel)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

}

extension SendCoordinator {

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
//          try? self?.balanceService.changeAddress(account.address)
          return;
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
