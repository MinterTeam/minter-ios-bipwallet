//
//  BIPWelcomeViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class WelcomeViewController: BaseViewController, Controller, WelcomeModule {

  // MARK: - WelcomeModule

  var onFinish: Completion?

  // MARK: - ControllerProtocol

  typealias ViewModelType = WelcomeViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: WelcomeViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)

    self.view.backgroundColor = .red
  }

}
