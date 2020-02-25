//
//  SendViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendViewController: BaseViewController, Controller {

  // MARK: - ControllerProtocol

  typealias ViewModelType = SendViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SendViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
