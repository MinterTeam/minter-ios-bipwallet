//
//  ContactRemoveConfirmationCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 05/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum ContactRemoveConfirmationCoordinatorResult {
  case confirm(contactItem: ContactItem)
  case cancel
}

class ContactRemoveConfirmationCoordinator: BaseCoordinator<ContactRemoveConfirmationCoordinatorResult> {

  let rootViewController: UIViewController
  let contactItem: ContactItem

  init(rootViewController: UIViewController, contact: ContactItem) {
    self.rootViewController = rootViewController
    self.contactItem = contact
  }

  override func start() -> Observable<ContactRemoveConfirmationCoordinatorResult> {
    let viewModel = ContactRemoveConfirmationViewModel(contact: contactItem, dependency: ContactRemoveConfirmationViewModel.Dependency())
    let controller = ContactRemoveConfirmationViewController.initFromStoryboard(name: "ContactRemoveConfirmation")
    controller.viewModel = viewModel
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.present(controller, animated: true, completion: nil)

    viewModel.output.didConfirm.subscribe(onNext: { (_) in
      controller.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)

    let resultObservable = Observable.of(
      controller.rx.viewDidDisappear.map {_ in ContactRemoveConfirmationCoordinatorResult.cancel },
      viewModel.output.didConfirm.map { item in ContactRemoveConfirmationCoordinatorResult.confirm(contactItem: self.contactItem) }
    ).merge()

    return resultObservable.take(1)
  }

}
