//
//  ConvertPopupViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class DelegateUnbondConfirmPopupViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let actionDidTap = PublishSubject<Void>()
  private let cancelDidTap = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: DelegateUnbondConfirmPopupViewModel.Input!
  var output: DelegateUnbondConfirmPopupViewModel.Output!
  var dependency: DelegateUnbondConfirmPopupViewModel.Dependency!

  struct Input {
    var actionDidTap: AnyObserver<Void>
    var cancelDidTap: AnyObserver<Void>
  }

  struct Output {
    var actionDidTap: Observable<Void>
    var cancelDidTap: Observable<Void>
    var amountText: Observable<String?>
    var validatorText: Observable<String?>
    var title: Observable<String>
    var desc: Observable<String>
    var toFrom: Observable<String>
  }

  struct Dependency {}

  init(dependency: Dependency,
       title: String,
       desc: String,
       toFrom: String,
       amountText: String?,
       validatorText: String?) {

    super.init()

    self.dependency = dependency

    self.input = Input(actionDidTap: actionDidTap.asObserver(),
                       cancelDidTap: cancelDidTap.asObserver()
    )

    self.output = Output(actionDidTap: actionDidTap.asObservable(),
                         cancelDidTap: cancelDidTap.asObservable(),
                         amountText: Observable.just(amountText),
                         validatorText: Observable.just(validatorText),
                         title: Observable.just(title),
                         desc: Observable.just(desc),
                         toFrom: Observable.just(toFrom)
    )
  }
}
