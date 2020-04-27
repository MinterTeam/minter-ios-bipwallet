//
//  SignInViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import GoldenKeystore
import MinterMy

class SignInViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let viewDidDisappear = PublishSubject<Bool>()
  private let title = BehaviorSubject<String>(value: "Sign In")
  private let shakeError = PublishSubject<Void>()
  private let hardImpact = PublishSubject<Void>()
  private let errorMessage = PublishSubject<String>()
  private let mnemonics = BehaviorRelay<String?>(value: "")
  private let mnemonicSaved = PublishSubject<Void>()
  private let isLoading = PublishSubject<Bool>()
  private let didTapGo = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SignInViewModel.Input!
  var output: SignInViewModel.Output!
  var dependency: SignInViewModel.Dependency!

  struct Input {
    var viewDidDisappear: AnyObserver<Bool>
    var didTapGo: AnyObserver<Void>
  }

  struct Output {
    var viewDidDisappear: Observable<Bool>
    var title: Observable<String>
    var shakeError: Observable<Void>
    var hardImpact: Observable<Void>
    var errorMessage: Observable<String>
    var mnemonics: BehaviorRelay<String?>
    var mnemonicSaved: Observable<Void>
    var isLoading: Observable<Bool>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {

    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver(),
                       didTapGo: didTapGo.asObserver()
    )

    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable(),
                         title: title.asObservable(),
                         shakeError: shakeError.asObservable(),
                         hardImpact: hardImpact.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         mnemonics: mnemonics,
                         mnemonicSaved: mnemonicSaved.asObservable(),
                         isLoading: isLoading.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {
    didTapGo.withLatestFrom(mnemonics).distinctUntilChanged()
//    .filter({ (str) -> Bool in
//      return str?.hasSuffix("\n") ?? false
//    })
      .map { $0?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? "" }
      .filter({ (str) -> Bool in
        return mnemonicIsValid(str)
      })
      .flatMap {
        self.addMnemonics(mnemonics: $0)
          .do(onNext: { (_) in
          self.isLoading.onNext(false)
        }, onError: { (error) in
          self.isLoading.onNext(false)
        }, onCompleted: {
          self.isLoading.onNext(false)
        }, onSubscribe: {
          self.isLoading.onNext(true)
        }).materialize()
      }.subscribe(onNext: { [weak self] (val) in
        guard let `self` = self else { return }

        switch val {
        case .next(let item):
          self.mnemonicSaved.onNext(())
          return

        case .error(let error):
          self.shakeError.onNext(())
          self.errorMessage.onNext("Incorrect mnemonic phrase".localized())
          self.hardImpact.onNext(())

        case .completed:
          return
        }
    }).disposed(by: disposeBag)
  }

  func addMnemonics(mnemonics: String) -> Observable<AccountItem> {
    return self.dependency.authService.addAccount(with: mnemonics, title: nil)
  }

}
