//
//  WelcomeViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class WelcomeViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let didTapSignIn = PublishSubject<Void>()
  private let didTapCreateWallet = PublishSubject<Void>()
  private let didTapHelp = PublishSubject<Void>()

  private let showSignIn = PublishSubject<Void>()
  private let showCreateWallet = PublishSubject<Void>()
  private let showHelp = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: WelcomeViewModel.Input!
  var output: WelcomeViewModel.Output!
  var dependency: WelcomeViewModel.Dependency!

  struct Input {
    var didTapSignIn: AnyObserver<Void>
    var didTapCreateWallet: AnyObserver<Void>
    var didTapHelp: AnyObserver<Void>
  }

  struct Output {
    var showSignIn: Observable<Void>
    var showCreateWallet: Observable<Void>
    var showHelp: Observable<Void>
  }

  struct Dependency {}

  init(dependency: Dependency) {
    self.input = Input(didTapSignIn: didTapSignIn.asObserver(),
                       didTapCreateWallet: didTapCreateWallet.asObserver(),
                       didTapHelp: didTapHelp.asObserver())
    self.output = Output(showSignIn: showSignIn.asObservable(),
                         showCreateWallet: showCreateWallet.asObservable(),
                         showHelp: showHelp.asObservable())
    self.dependency = dependency

    super.init()
    bind()
  }

  // MARK: -
  
  private func bind() {
    didTapSignIn.asDriver(onErrorJustReturn: ()).drive(showSignIn).disposed(by: disposeBag)
    didTapCreateWallet.asDriver(onErrorJustReturn: ()).drive(showCreateWallet).disposed(by: disposeBag)
    didTapHelp.asDriver(onErrorJustReturn: ()).drive(showHelp).disposed(by: disposeBag)
  }

}
