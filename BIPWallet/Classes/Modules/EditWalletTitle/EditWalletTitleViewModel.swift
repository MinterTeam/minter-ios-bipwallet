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
}

class EditWalletTitleViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let title = BehaviorRelay<String?>(value: nil)
  private let shakeError = PublishSubject<Void>()
  private let hardImpact = PublishSubject<Void>()
  private let errorMessage = PublishSubject<String>()
  private let didSubmit = PublishSubject<Void>()
  private let didChange = PublishSubject<Void>()
  private let willDismiss = PublishSubject<Void>()

  private var accountItem: AccountItem

  // MARK: - ViewModel

  var input: EditWalletTitleViewModel.Input!
  var output: EditWalletTitleViewModel.Output!
  var dependency: EditWalletTitleViewModel.Dependency!

  struct Input {
    var title: BehaviorRelay<String?>
    var didSubmit: AnyObserver<Void>
    var willDismiss: AnyObserver<Void>
  }

  struct Output {
    var shakeError: Observable<Void>
    var hardImpact: Observable<Void>
    var errorMessage: Observable<String>
    var didChange: Observable<Void>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(account: AccountItem, dependency: Dependency) {
    self.input = Input(title: title,
                       didSubmit: didSubmit.asObserver(),
                       willDismiss: willDismiss.asObserver()
    )

    self.output = Output(shakeError: shakeError.asObservable(),
                         hardImpact: hardImpact.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         didChange: didChange.asObservable()
    )

    self.dependency = dependency

    self.accountItem = account

    super.init()

    bind()
  }

  // MARK: -

  func bind() {
    //Stop receiveing didSubmit events on VC dismiss
    willDismiss.subscribe(onNext: { (_) in
      self.didSubmit.onCompleted()
    }).disposed(by: disposeBag)

    didSubmit.withLatestFrom(title).filter({ (title) -> Bool in
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
  }

  func validateForm(_ title: String?) -> Observable<String> {
    return Observable<String>.create { (observer) -> Disposable in
      if let newTitle = title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
        newTitle.isValidWalletTitle() {
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
        errorTitle = "Invalid title. It must be from 3 to 18 latin characters and numbers".localized()
      }
    }
    self.errorMessage.onNext(errorTitle)
    self.shakeError.onNext(())
    self.hardImpact.onNext(())
  }

}
