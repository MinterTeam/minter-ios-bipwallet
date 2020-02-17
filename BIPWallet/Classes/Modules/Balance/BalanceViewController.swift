//
//  BalanceViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class BalanceViewController: BaseViewController, Controller {

  // MARK: - ControllerProtocol

  typealias ViewModelType = BalanceViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: BalanceViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
    
    view.backgroundColor = .blue
  }

}
