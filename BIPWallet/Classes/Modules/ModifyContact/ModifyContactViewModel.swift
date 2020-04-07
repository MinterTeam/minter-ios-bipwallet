//
//  ModifyContactViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 30/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum ModifyContactViewModelError: Error {
  case invalidAddress
  case invalidName
}

class ModifyContactViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private(set) var contactItem: ContactItem?

  private let address = BehaviorRelay<String?>(value: nil)
  private let name = BehaviorRelay<String?>(value: nil)
  private let didTapGoButton = PublishSubject<Void>()
  private let errorNotification = PublishSubject<NotifiableError?>()
  private let shakeError = PublishSubject<Void>()
  private let showSuccess = PublishSubject<String?>()
  private let switchKeybordToTitle = PublishSubject<Void>()
  private let didAddContactWithAddress = PublishSubject<ContactItem?>()

  // MARK: - ViewModel

  var input: ModifyContactViewModel.Input!
  var output: ModifyContactViewModel.Output!
  var dependency: ModifyContactViewModel.Dependency!

  struct Input {
    var didTapGoButton: AnyObserver<Void>
  }

  struct Output {
    var address: BehaviorRelay<String?>
    var name: BehaviorRelay<String?>
    var errorNotification: Observable<NotifiableError?>
    var shakeError: Observable<Void>
    var showSuccess: Observable<String?>
    var switchKeybordToTitle: Observable<Void>
    var didAddContactWithAddress: Observable<ContactItem?>
  }

  struct Dependency {
    var contactsService: ContactsService
  }

  init(contactItem: ContactItem? = nil, dependency: Dependency) {

    self.contactItem = contactItem
    self.input = Input(didTapGoButton: didTapGoButton.asObserver())

    self.output = Output(address: address,
                         name: name,
                         errorNotification: errorNotification.asObservable(),
                         shakeError: shakeError.asObservable(),
                         showSuccess: showSuccess.asObservable(),
                         switchKeybordToTitle: switchKeybordToTitle.asObservable(),
                         didAddContactWithAddress: didAddContactWithAddress.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {

    didTapGoButton.subscribe(onNext: { [weak self] (_) in
      self?.saveForm()
    }).disposed(by: disposeBag)

    address
      .observeOn(MainScheduler.asyncInstance)
      .filter({ (value) -> Bool in
        return value?.hasSuffix("\n") ?? false
      }).do(onNext: { (value) in
        self.address.accept((value ?? "").replacingOccurrences(of: "\n", with: ""))
      }).map { _ in Void() }.subscribe(switchKeybordToTitle)
      .disposed(by: disposeBag)

    if let contactItem = self.contactItem {
      self.address.accept(contactItem.address)
      self.name.accept(contactItem.name)
    }
  }

  func saveForm() {
    Observable<Void>.of(Void()).withLatestFrom(form())
    .flatMap {
      return self.validForm(name: self.normalizeName(name: $0.0 ?? ""), address: $0.1 ?? "")
    }
    .do(onError: { [weak self] (error) in
      self?.shakeError.onNext(())
      var errorTitle = "An Error occured".localized()
      if let error = error as? ModifyContactViewModelError {
        switch error {
        case .invalidAddress:
          errorTitle = "Invalid Address".localized()
        case .invalidName:
          errorTitle = "Invalid Title".localized()
        }
      } else if let error = error as? ContactsServiceError {
        switch error {
        case .dublicateContact:
          errorTitle = "Contact with such title or address already exists".localized()
        case .incorrectParam:
          errorTitle = "Incorrect title or address".localized()
        case .cantSaveContact:
          errorTitle = "Unable to save contact".localized()
        }
      }
      let notifiableError = NotifiableError(title: errorTitle, text: nil)
      self?.errorNotification.onNext(notifiableError)
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
        self?.switchKeybordToTitle.onNext(())
      }
    })
    .withLatestFrom(form())
    .subscribe(onNext: { [weak self] (form) in
      //Show address saved
      let name = form.0
      let address = form.1
      self?.showSuccess.onNext(name)
      let contact = ContactItem(name: name, address: address)
      self?.didAddContactWithAddress.onNext(contact)
    }).disposed(by: disposeBag)
  }

  func form() -> Observable<(String?, String?)> {
    return Observable.combineLatest(name.asObservable(), address.asObservable())
  }

  func validForm(name: String, address: String) -> Observable<Void> {
    return Observable<Void>.create { (observer) -> Disposable in
      let isValidName = self.isValidName(name: name)
      let isValidAddress = address.isValidAddress()
      let isValidPublicKey = address.isValidPublicKey()

      if isValidName && (isValidAddress || isValidPublicKey) {
        observer.onNext(())
      } else {
        if !isValidName {
          observer.onError(ModifyContactViewModelError.invalidName)
        } else {
          observer.onError(ModifyContactViewModelError.invalidAddress)
        }
      }
      observer.onCompleted()
      return Disposables.create()
    }.flatMap { (_) -> Observable<Void> in
      let item = ContactItem(name: name, address: address)
      if let currentItem = self.contactItem {
        return try! self.dependency.contactsService.edit(currentItem, newItem: item)
      } else {
        return try! self.dependency.contactsService.add(item: item)
      }
    }
  }

  func normalizeName(name: String) -> String {
    return name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
  }

  func isValidName(name: String) -> Bool {
    return name.isValidContactName()
  }

}
