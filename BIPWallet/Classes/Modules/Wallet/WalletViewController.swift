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

  func configure(with viewModel: WalletViewModel) {}

  func configureDefault() {}

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
