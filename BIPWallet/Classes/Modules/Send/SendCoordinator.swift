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

  private let navigationController: UINavigationController

  let authService: AuthService
  let balanceService: BalanceService

  init(navigationController: UINavigationController, balanceService: BalanceService, authService: AuthService) {
    self.navigationController = navigationController
    self.authService = authService
    self.balanceService = balanceService

    super.init()

    balanceService.updateBalance()
  }

  override func start() -> Observable<Void> {
    let contactService = LocalStorageContactsService()
    let controller = SendViewController.initFromStoryboard(name: "Send")
    let dependency = SendViewModel.Dependency(balanceService: balanceService,
                                              contactsService: contactService)
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
    }).do(onNext: { (item) in
      
    }).subscribe(viewModel.input.contact).disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)
    return Observable.never()
  }

  func showContacts(rootViewController: UIViewController) -> Observable<ContactItem?> {
    let contactsCoordinator = ContactPickerCoordinator(rootViewController: rootViewController)
    return coordinate(to: contactsCoordinator).map { (result) -> ContactItem? in
      switch result {
      case .contact(let item):
        return item
      case .cancel:
        return nil
      }
    }
  }

}
