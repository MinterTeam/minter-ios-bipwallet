//
//  Controller.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol Controller: class {

  var viewModel: ViewModelType! { get set }

  associatedtype ViewModelType: ViewModel
  /// Configurates controller with specified ViewModelProtocol subclass
  ///
  /// - Parameter viewModel: ViewModel subclass instance to configure with
  func configure(with viewModel: ViewModelType)

  func configureDefault()
}

extension Controller where Self: BaseViewController {

  func configureDefault() {

    viewModel.impact.asDriver(onErrorJustReturn: .light).drive(onNext: { (type) in
      switch type {
      case .light:
        self.lightImpactFeedbackGenerator.prepare()
        self.lightImpactFeedbackGenerator.impactOccurred()

      case .hard:
        self.hardImpactFeedbackGenerator.prepare()
        self.hardImpactFeedbackGenerator.impactOccurred()
      }
    }).disposed(by: disposeBag)

    viewModel.sound.asDriver(onErrorJustReturn: .cancel).drive(onNext: { (type) in
      SoundHelper.playSoundIfAllowed(type: type)
    }).disposed(by: disposeBag)

    viewModel.showErrorMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performErrorNotification(title: message)
    }).disposed(by: disposeBag)

    viewModel.showSuccessMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performSuccessNotification(title: message)
    }).disposed(by: disposeBag)

    viewModel.showNotifyMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performNotifyNotification(title: message)
    }).disposed(by: disposeBag)
  }
}
