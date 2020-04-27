//
//  CreateWalletViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore

enum CreateWalletViewModelError: Error {
  case incorrectMnemonics
}

class CreateWalletViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let viewDidDisappear = PublishSubject<Bool>()
  private let isSwichOn = PublishSubject<Bool>()
  private let mnemonic = BehaviorSubject<String?>(value: String.generateMnemonicString())
  private let isLoading = PublishSubject<Bool>()
  private let didTapActivate = PublishSubject<Void>()
  private let mnemonicSaved = PublishSubject<Void>()
  private let didTapMnemonic = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: CreateWalletViewModel.Input!
  var output: CreateWalletViewModel.Output!
  var dependency: CreateWalletViewModel.Dependency!

  struct Input {
    var viewDidDisappear: AnyObserver<Bool>
    var isSwichOn: AnyObserver<Bool>
    var didTapActivate: AnyObserver<Void>
    var didTapMnemonic: AnyObserver<Void>
  }

  struct Output {
    var viewDidDisappear: Observable<Bool>
    var mnemonic: Observable<String?>
    var isButtonEnabled: Observable<Bool>
    var mnemonicSaved: Observable<Void>
    var isLoading: Observable<Bool>
    var buttonTitle: Observable<String>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {
    self.input = Input(viewDidDisappear: viewDidDisappear.asObserver(),
                       isSwichOn: isSwichOn.asObserver(),
                       didTapActivate: didTapActivate.asObserver(),
                       didTapMnemonic: didTapMnemonic.asObserver())

    self.output = Output(viewDidDisappear: viewDidDisappear.asObservable(),
                         mnemonic: mnemonic.asObservable(),
                         isButtonEnabled: isSwichOn,
                         mnemonicSaved: mnemonicSaved.asObservable(),
                         isLoading: isLoading.asObservable(),
                         buttonTitle: isLoading.map { loading in loading ? "" : "Activate Wallet" }
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {

    didTapMnemonic.asObservable().subscribe(onNext: { (_) in
      guard let mnemonic = try? self.mnemonic.value() else {
        //show error
        return
      }

      UIPasteboard.general.string = mnemonic
    }).disposed(by: disposeBag)

    didTapActivate.observeOn(MainScheduler.asyncInstance).asObservable().do(onNext: { (_) in
      self.isLoading.onNext(true)
    }, onError: { (error) in
      self.isLoading.onNext(false)
    }, onCompleted: {
      self.isLoading.onNext(false)
    }, onSubscribe: {
      self.isLoading.onNext(true)
    }).flatMap({ (_) -> Observable<AccountItem> in
      guard let mnemonic = try? self.mnemonic.value() else {
        return Observable.error(CreateWalletViewModelError.incorrectMnemonics)
      }
      return self.dependency.authService.addAccount(with: mnemonic, title: nil)
    }).map{_ in}.subscribe(mnemonicSaved).disposed(by: disposeBag)

  }

}
