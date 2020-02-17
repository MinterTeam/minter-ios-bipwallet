//
//  WalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class WalletViewController: BaseViewController, Controller {

  // MARK: - ControllerProtocol

  typealias ViewModelType = WalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: WalletViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
