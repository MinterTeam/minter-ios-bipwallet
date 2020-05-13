//
//  EditWalletTitleViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 09/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum EditWalletTitleViewModelError: Error {
  case invalidTitle
  case dublicateTitle
}

class EditWalletTitleViewModel: BaseViewModel, ViewModel {

  // MARK: -

  lazy var title = BehaviorRelay<String?>(value: self.accountItem.title)
  private let shakeError = PublishSubject<Void>()
  private let hardImpact = PublishSubject<Void>()
  private let errorMessage = PublishSubject<String>()
  private let didTapSave = PublishSubject<Void>()
  private let didTapRemove = PublishSubject<Void>()
  private let didChange = PublishSubject<Void>()
  private let didRemove = PublishSubject<Void>()
  private let willDismiss = PublishSubject<Void>()
  private let shouldHideRemoveButton = PublishSubject<Bool>()

  private var accountItem: AccountItem
  private let isLastAccount: Bool

  // MARK: - ViewModel

  var input: EditWalletTitleViewModel.Input!
  var output: EditWalletTitleViewModel.Output!
  var dependency: EditWalletTitleViewModel.Dependency!

  struct Input {
    var title: BehaviorRelay<String?>
    var didTapSave: AnyObserver<Void>
    var didTapRemove: AnyObserver<Void>
    var willDismiss: AnyObserver<Void>
  }

  struct Output {
    var shakeError: Observable<Void>
    var hardImpact: Observable<Void>
    var errorMessage: Observable<String>
    var didChange: Observable<Void>
    var didRemove: Observable<Void>
    var shouldHideRemoveButton: Observable<Bool>
    var text: Observable<NSAttributedString?>
    var walletTitle: Observable<String?>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(account: AccountItem, isLastAccount: Bool, dependency: Dependency) {
    self.accountItem = account
    self.isLastAccount = isLastAccount

    super.init()

    self.input = Input(title: title,
                       didTapSave: didTapSave.asObserver(),
                       didTapRemove: didTapRemove.asObserver(),
                       willDismiss: willDismiss.asObserver()
    )

    self.output = Output(shakeError: shakeError.asObservable(),
                         hardImpact: hardImpact.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         didChange: didChange.asObservable(),
                         didRemove: didRemove.asObservable(),
                         shouldHideRemoveButton: Observable.of(self.isLastAccount),
                         text: Observable.just(text()),
                         walletTitle: Observable.just(account.title)
    )

    self.dependency = dependency

    bind()
  }

  // MARK: -

  func bind() {

    didTapSave.withLatestFrom(title).filter({ (title) -> Bool in
      return true
    }).flatMap { [weak self] (title) -> Observable<Event<String>> in
      guard let `self` = self else { return Observable.empty() }
      return self.validateForm(title).materialize()
    }.flatMap({ [weak self] (event) -> Observable<Void> in
      guard let `self` = self else { return Observable.empty() }
      switch event {
      case .next(let title):
        self.accountItem.title = title
        return self.dependency.authService.updateAccount(account: self.accountItem)
      case .error(let error):
        self.handleError(error)
        return Observable.empty()
      default:
        return Observable.empty()
      }
    }).subscribe(didChange).disposed(by: disposeBag)

    didTapRemove.subscribe(onNext: { (_) in
      try? self.dependency.authService.remove(account: self.accountItem)
      self.didRemove.onNext(())
      self.impact.onNext(.hard)
      self.sound.onNext(.click)
    }).disposed(by: disposeBag)

  }

  func validateForm(_ title: String?) -> Observable<String> {
    return Observable<String>.create { (observer) -> Disposable in
      if let newTitle = title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
        newTitle.isValidWalletTitle() {
        if let title = title {
          guard self.dependency.authService.accounts().filter { (item) -> Bool in
            return item.title == title && item.address != self.accountItem.address
          }.isEmpty else {
            observer.onError(EditWalletTitleViewModelError.dublicateTitle)
            return Disposables.create()
          }
        }
        observer.onNext(newTitle)
      } else {
        observer.onError(EditWalletTitleViewModelError.invalidTitle)
      }
      return Disposables.create()
    }
  }

  func handleError(_ error: Error) {
    var errorTitle = "Unable to change the title".localized()
    if let error = error as? EditWalletTitleViewModelError {
      switch error {
      case .invalidTitle:
        errorTitle = "Invalid title. It must be up to 18 latin characters and numbers".localized()
      case .dublicateTitle:
        errorTitle = "You've already added a wallet with this title".localized()
      }
    }
    self.errorMessage.onNext(errorTitle)
    self.shakeError.onNext(())
    self.hardImpact.onNext(())
  }

  func text() -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Are you sure, you want to remove wallet ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    string.append(NSAttributedString(string: accountItem.address,
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 14.0)]))
    string.append(NSAttributedString(string: " from this application?\n\n".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))
    string.append(NSAttributedString(string: "Attention! ",
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 14.0)]))
    string.append(NSAttributedString(string: "The wallet will not be deleted from blockchain. You’ll be able to readd it later with the saved seed-phrase.".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 14.0)]))

    return string
  }

}
