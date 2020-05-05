//
//  WalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class WalletViewController: UITabBarController, Controller, StoryboardInitializable {

  var disposeBag = DisposeBag()

  // MARK: - ControllerProtocol

  typealias ViewModelType = WalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: WalletViewModel) {

  }

  func configureDefault() {

//    viewModel.impact.asDriver(onErrorJustReturn: .light).drive(onNext: { (type) in
//      switch type {
//      case .light:
////        self.lightImpactFeedbackGenerator.prepare()
//        self.lightImpactFeedbackGenerator.impactOccurred()
//
//      case .hard:
//        self.hardImpactFeedbackGenerator.prepare()
//        self.hardImpactFeedbackGenerator.impactOccurred()
//      }
//    }).disposed(by: disposeBag)
//
//    viewModel.sound.asDriver(onErrorJustReturn: .cancel).drive(onNext: { (type) in
//      SoundHelper.playSoundIfAllowed(type: type)
//    }).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

  override var childForStatusBarStyle: UIViewController? {
    let candidate = self.viewControllers?[safe: self.selectedIndex]
    if let navBar = candidate as? UINavigationController {
      return navBar.viewControllers.last
    }
    return candidate
  }

}
