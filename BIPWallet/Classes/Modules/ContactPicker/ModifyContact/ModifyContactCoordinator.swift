//
//  ModifyContactCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 30/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

class ModifyContactCoordinator: BaseCoordinator<ContactItem?> {

  private var rootViewController: UIViewController
  private var contactItem: ContactItem?
  /// Used if needs to add by address
  private var address: String?
  let contactsService: ContactsService

  init(contactItem: ContactItem? = nil, rootViewController: UIViewController, contactsService: ContactsService) {
    self.rootViewController = rootViewController
    self.contactItem = contactItem
    self.contactsService = contactsService
  }

  init(address: String, rootViewController: UIViewController, contactsService: ContactsService) {
    self.rootViewController = rootViewController
    self.address = address
    self.contactsService = contactsService
  }

  override func start() -> Observable<ContactItem?> {
    let dependency = ModifyContactViewModel.Dependency(contactsService: contactsService)
    let viewModel = ModifyContactViewModel(contactItem: contactItem, address: address, dependency: dependency)
    let viewController = ModifyContactViewController.initFromStoryboard(name: "ModifyContact")
    viewController.viewModel = viewModel

    let presentingVC = ClearBarNavigationController(rootViewController: viewController)
    presentingVC.modalTransitionStyle = .coverVertical
    presentingVC.modalPresentationStyle = .overCurrentContext

    rootViewController.present(presentingVC,
                               animated: true) {}

    return viewController.rx.viewDidDisappear.withLatestFrom(viewModel.output.didAddContactWithAddress)
  }

}
