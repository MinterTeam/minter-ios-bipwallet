//
//  WelcomeViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WelcomeViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var signInButton: DefaultButton!
  @IBOutlet weak var createWalletButton: DefaultButton!
  @IBOutlet weak var helpButton: DefaultButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = WelcomeViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: WelcomeViewModel) {
    signInButton.rx.tap.asDriver().drive(viewModel.input.didTapSignIn).disposed(by: disposeBag)
    createWalletButton.rx.tap.asDriver().drive(viewModel.input.didTapCreateWallet).disposed(by: disposeBag)
    helpButton.rx.tap.asDriver().drive(viewModel.input.didTapHelp).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

}
