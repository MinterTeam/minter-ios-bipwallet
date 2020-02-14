//
//  CreateWalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class CreateWalletViewController: BaseViewController, Controller {

  // MARK: - ControllerProtocol

  typealias ViewModelType = CreateWalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: CreateWalletViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
