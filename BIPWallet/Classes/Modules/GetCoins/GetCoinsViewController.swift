//
//  GetCoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class GetCoinsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - ControllerProtocol

  typealias ViewModelType = GetCoinsViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: GetCoinsViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
