//
//  SendSucceedPopupViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class SendSucceedPopupViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let didTapAction = PublishSubject<Void>()
  private let didTapSecondary = PublishSubject<Void>()
  private let didTapClose = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SendSucceedPopupViewModel.Input!
  var output: SendSucceedPopupViewModel.Output!
  var dependency: SendSucceedPopupViewModel.Dependency!

  struct Input {
    var didTapAction: AnyObserver<Void>
    var didTapSecondary: AnyObserver<Void>
    var didTapClose: AnyObserver<Void>
  }

  struct Output {
    var hideActionButton: Bool
    var recipient: Observable<String?>
    var didTapAction: Observable<Void>
    var didTapSecondary: Observable<Void>
    var didTapClose: Observable<Void>
  }

  struct Dependency {

  }

  var recipient: String?

  init(dependency: Dependency, shouldHideActionButton: Bool, recipient: String?) {
    self.recipient = recipient
    super.init()

    self.dependency = dependency

    self.input = Input(didTapAction: didTapAction.asObserver(),
                       didTapSecondary: didTapSecondary.asObserver(),
                       didTapClose: didTapClose.asObserver()
    )

    self.output = Output(hideActionButton: shouldHideActionButton,
                         recipient: Observable.just(recipient),
                         didTapAction: didTapAction.asObservable(),
                         didTapSecondary: didTapSecondary.asObservable(),
                         didTapClose: didTapClose.asObservable()
    )
  }

  // MARK: -

}
