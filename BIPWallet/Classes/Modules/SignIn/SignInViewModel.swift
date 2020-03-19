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
  private let mnemonics = BehaviorRelay<String?>(value: nil)
  private let mnemonicSaved = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SignInViewModel.Input!
  var output: SignInViewModel.Output!
  var dependency: SignInViewModel.Dependency!

  struct Input {
    var viewDidDisappear: AnyObserver<Bool>
  }

  struct Output {
    var viewDidDisappear: Observable<Bool>
    var title: Observable<String>
    var shakeError: Observable<Void>
    var hardImpact: Observable<Void>
    var errorMessage: Observable<String>
    var mnemonics: BehaviorRelay<String?>
    var mnemonicSaved: Observable<Void>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {
    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver())
    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable(),
                         title: title.asObservable(),
                         shakeError: shakeError.asObservable(),
                         hardImpact: hardImpact.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         mnemonics: mnemonics,
                         mnemonicSaved: mnemonicSaved.asObservable()
    )
    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {
    mnemonics.subscribe(onNext: { [weak self] (val) in
      guard let `self` = self else { return }
      guard val?.hasSuffix("\n") ?? false else { return }
      let newVal = val?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      if let mnem = newVal, !mnemonicIsValid(mnem) {
        self.shakeError.onNext(())
        self.errorMessage.onNext("Incorrect mnemonic phrase".localized())
        self.hardImpact.onNext(())
      } else {
        //save mnemonics
        self.dependency.authService.addAccount(mnemonic: newVal ?? "")
        self.mnemonicSaved.onNext(())
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.mnemonics.accept(newVal)
      }
    }).disposed(by: disposeBag)
  }

}