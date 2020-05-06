//
//  ContactRemoveConfirmationViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 05/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ContactRemoveConfirmationViewModel: BaseViewModel, ViewModel {

  // MARK: -
  let contact: ContactItem

  private let didConfirm = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: ContactRemoveConfirmationViewModel.Input!
  var output: ContactRemoveConfirmationViewModel.Output!
  var dependency: ContactRemoveConfirmationViewModel.Dependency!

  struct Input {
    var didTapConfirmButton: AnyObserver<Void>
  }

  struct Output {
    var didConfirm: Observable<Void>
    var text: Observable<NSAttributedString?>
  }

  struct Dependency {

  }

  init(contact: ContactItem, dependency: Dependency) {
    self.contact = contact

    self.dependency = dependency

    super.init()

    self.input = Input(didTapConfirmButton: didConfirm.asObserver()
    )

    self.output = Output(didConfirm: didConfirm.asObservable(),
                         text: Observable.just(self.text())
    )

    bind()
  }

  // MARK: -

  func bind() {
    
  }

  func text() -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Are you sure, you want to remove ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    string.append(NSAttributedString(string: contact.address ?? "",
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 14.0)]))
    string.append(NSAttributedString(string: " from this application?".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))

    return string
  }

}
