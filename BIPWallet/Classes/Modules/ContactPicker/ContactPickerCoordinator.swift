//
//  ContactPickerCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 28/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum ContactPickerResult {
  case contact(ContactItem)
  case cancel
}

class ContactPickerCoordinator: BaseCoordinator<ContactPickerResult> {

  private let rootViewController: UIViewController
  private let contactsService: ContactsService

  init(rootViewController: UIViewController, contactsService: ContactsService) {
    self.rootViewController = rootViewController
    self.contactsService = contactsService

    super.init()
  }

  override func start() -> Observable<ContactPickerResult> {
    let controller = ContactPickerViewController.initFromStoryboard(name: "ContactPicker")
    let dependecy = ContactPickerViewModel.Dependency(contactsService: contactsService)
    let viewModel = ContactPickerViewModel(dependency: dependecy)
    controller.viewModel = viewModel

    let cancel = controller.rx.viewDidDisappear.map { _ in CoordinationResult.cancel }
    let contact = viewModel.output.didSelectContact.filter({ (item) -> Bool in
      return item != nil
    }).map { CoordinationResult.contact($0!) }.do(onNext: { [weak self] (result) in
      self?.rootViewController.navigationController?.popViewController(animated: true)
    })

    viewModel.output.showAddContact.flatMap({ (val) -> Observable<ContactItem?> in
      if let rootvc = UIApplication.shared.keyWindow?.rootViewController {
        return self.showAddContact(from: rootvc)
      }
      return Observable.just((nil))
    }).subscribe(viewModel.input.didAddContact).disposed(by: disposeBag)

    viewModel.output.editContact.flatMap({ (val) -> Observable<ContactItem?> in
      if let rootvc = UIApplication.shared.keyWindow?.rootViewController {
        return self.showEditContact(contactItem: val, from: rootvc)
      }
      return Observable.just((nil))
    }).subscribe(viewModel.input.didAddContact).disposed(by: disposeBag)

    viewModel.output.deleteContact.flatMap { (contact) -> Observable<ContactRemoveConfirmationCoordinatorResult> in
      guard let rootVC = controller.tabBarController else { return Observable.empty() }
      return self.showConfirmContactDelete(contactItem: contact, from: rootVC)
    }.subscribe(onNext: { (result) in
      switch result {
      case .confirm(let contact):
        viewModel.input.deleteContact.onNext(contact)

      case .cancel:
        return
      }
    }).disposed(by: disposeBag)

    rootViewController.navigationController?.pushViewController(controller, animated: true)

    return Observable.merge(cancel, contact).take(1)
  }

  func showAddContact(from: UIViewController) -> Observable<ContactItem?> {
    let addContact = ModifyContactCoordinator(rootViewController: from, contactsService: self.contactsService)
    return coordinate(to: addContact)
  }

  func showEditContact(contactItem: ContactItem, from: UIViewController) -> Observable<ContactItem?> {
    let addContact = ModifyContactCoordinator(contactItem: contactItem, rootViewController: from, contactsService: self.contactsService)
    return coordinate(to: addContact)
  }

  func showConfirmContactDelete(contactItem: ContactItem, from: UIViewController) -> Observable<ContactRemoveConfirmationCoordinatorResult> {
    let coordinator = ContactRemoveConfirmationCoordinator(rootViewController: from, contact: contactItem)
    return coordinate(to: coordinator)
  }

}
