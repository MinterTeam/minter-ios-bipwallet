//
//  ShareViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ShareViewModel: BaseViewModel, ViewModel {

  let account: AccountItem

  private let didTapCopy = PublishSubject<Void>()
  private let didTapImage = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let copied = PublishSubject<Void>()
  private let image = ReplaySubject<UIImage?>.create(bufferSize: 1)

  // MARK: - ViewModel

  var input: ShareViewModel.Input!
  var output: ShareViewModel.Output!
  var dependency: ShareViewModel.Dependency!

  struct Input {
    var didTapCopy: AnyObserver<Void>
    var didTapImage: AnyObserver<Void>
    var didTapShare: AnyObserver<Void>
  }

  struct Output {
    var image: Observable<UIImage?>
    var address: Observable<String>
    var copied: Observable<Void>
    var didTapShare: Observable<Void>
  }

  struct Dependency {}

  init(account: AccountItem, dependency: Dependency) {
    self.account = account

    self.input = Input(didTapCopy: didTapCopy.asObserver(),
                       didTapImage: didTapImage.asObserver(),
                       didTapShare: didTapShare.asObserver()
    )

    self.output = Output(image: image.asObservable(),
                         address: Observable.just(account.address),
                         copied: copied.asObservable(),
                         didTapShare: didTapShare.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {
    didTapCopy.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.account.address
      self?.copied.onNext(())
    }).disposed(by: disposeBag)

    DispatchQueue.global().async { [weak self] in
      guard let `self` = self else { return }
      let image = QRCode(self.account.address)?.image
      DispatchQueue.main.async {
        self.image.onNext(image)
      }
    }

  }

}
