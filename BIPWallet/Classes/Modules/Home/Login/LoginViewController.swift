//
//  LoginViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class LoginViewController: BaseViewController, Controller {

  // MARK: - ControllerProtocol

  typealias ViewModelType = LoginViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: LoginViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
