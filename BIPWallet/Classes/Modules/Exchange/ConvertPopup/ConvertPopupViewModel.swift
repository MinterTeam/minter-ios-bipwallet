//
//  ConvertPopupViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ConvertPopupViewModel: BaseViewModel, ViewModel {

  // MARK: -
  
  var fromText: String?
  var toText: String?

  private let actionDidTap = PublishSubject<Void>()
  private let cancelDidTap = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: ConvertPopupViewModel.Input!
  var output: ConvertPopupViewModel.Output!
  var dependency: ConvertPopupViewModel.Dependency!

  struct Input {
    var actionDidTap: AnyObserver<Void>
    var cancelDidTap: AnyObserver<Void>
  }

  struct Output {
    var actionDidTap: Observable<Void>
    var cancelDidTap: Observable<Void>
    var fromText: Observable<String?>
    var toText: Observable<String?>
  }

  struct Dependency {}

  init(dependency: Dependency, fromText: String?, toText: String?) {
    super.init()
    self.fromText = fromText
    self.toText = toText

    self.dependency = dependency

    self.input = Input(actionDidTap: actionDidTap.asObserver(),
                       cancelDidTap: cancelDidTap.asObserver()
    )

    self.output = Output(actionDidTap: actionDidTap.asObservable(),
                         cancelDidTap: cancelDidTap.asObservable(),
                         fromText: Observable.just(fromText),
                         toText: Observable.just(toText)
    )

    bind()
  }

  // MARK: -

  func bind() {
    
  }

}
