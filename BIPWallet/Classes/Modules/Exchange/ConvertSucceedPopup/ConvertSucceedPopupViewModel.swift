//
//  ConvertSucceedPopupViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ConvertSucceedPopupViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let didTapAction = PublishSubject<Void>()
  private let didTapCancel = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: ConvertSucceedPopupViewModel.Input!
  var output: ConvertSucceedPopupViewModel.Output!
  var dependency: ConvertSucceedPopupViewModel.Dependency!

  struct Input {
    var didTapAction: AnyObserver<Void>
    var didTapCancel: AnyObserver<Void>
  }

  struct Output {
    var didTapAction: Observable<Void>
    var didTapCancel: Observable<Void>
    var description: Observable<String?>
  }

  struct Dependency {}

  init(dependency: Dependency, message: String?) {
    super.init()

    self.input = Input(didTapAction: didTapAction.asObserver(),
                       didTapCancel: didTapCancel.asObserver()
    )

    self.output = Output(didTapAction: didTapAction.asObservable(),
                         didTapCancel: didTapCancel.asObservable(),
                         description: Observable.just(message)
    )

    self.dependency = dependency
  }

  // MARK: -

}
