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

  init(contactItem: ContactItem? = nil, rootViewController: UIViewController) {
    self.rootViewController = rootViewController
    self.contactItem = contactItem
  }

  override func start() -> Observable<ContactItem?> {
    let contactService = LocalStorageContactsService()
    let dependency = ModifyContactViewModel.Dependency(contactsService: contactService)
    let viewModel = ModifyContactViewModel(contactItem: contactItem, dependency: dependency)
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
