//
//  SendSucceedPopupViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendSucceedPopupViewController: PopupViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var descTitle: UILabel!
  @IBOutlet weak var receiverLabel: UILabel!
  @IBOutlet weak var actionButton: DefaultButton!
  @IBOutlet weak var secondActionButton: DefaultButton!
  @IBOutlet weak var secondButton: DefaultButton!
  @IBOutlet weak var actionButtonTopLayoutConstraint: NSLayoutConstraint!

  // MARK: - ControllerProtocol

  typealias ViewModelType = SendSucceedPopupViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SendSucceedPopupViewModel) {
    //Output
    viewModel.output.recipient.asDriver(onErrorJustReturn: nil)
      .drive(receiverLabel.rx.text).disposed(by: disposeBag)

    if viewModel.output.hideActionButton {
      hideActionButton()
    }

    //Input
    actionButton.rx.tap.asDriver().drive(viewModel.input.didTapAction).disposed(by: disposeBag)
    secondActionButton.rx.tap.asDriver().drive(viewModel.input.didTapSecondary).disposed(by: disposeBag)
    secondButton.rx.tap.asDriver().drive(viewModel.input.didTapClose).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)
  }

  // MARK: -

  private func updateUI() {

  }
  
  func hideActionButton() {
    self.actionButton.alpha = 0.0
    self.actionButtonTopLayoutConstraint.constant = -43.0
  }
}
