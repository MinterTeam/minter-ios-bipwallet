//
//  SpendCoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SpendCoinsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - ControllerProtocol

  typealias ViewModelType = SpendCoinsViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SpendCoinsViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
