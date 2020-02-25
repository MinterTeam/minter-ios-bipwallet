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

class CreateWalletViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let viewDidDisappear = PublishSubject<Bool>()
  private let isSwichOn = PublishSubject<Bool>()
  private let mnemonic = BehaviorSubject<String?>(value: String.generateMnemonicString())
//  private let isButtonEnabled = PublishSubject<Bool>()
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
                         mnemonicSaved: mnemonicSaved.asObservable()
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

    didTapActivate.asObservable().subscribe(onNext: { (_) in
      guard let mnemonic = try? self.mnemonic.value() else {
        //show error
        return
      }

      self.dependency.authService.addAccount(mnemonic: mnemonic)
      self.mnemonicSaved.onNext(())
      }).disposed(by: disposeBag)

  }

}
