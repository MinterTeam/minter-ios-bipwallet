//
//  TransactionViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class TransactionViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - ControllerProtocol

  typealias ViewModelType = TransactionViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: TransactionViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
