//
//  ConvertSucceedPopupViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class DelegateUnbondSucceedPopupViewController: PopupViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = DelegateUnbondSucceedPopupViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: DelegateUnbondSucceedPopupViewModel) {
    //Input
    actionButton.rx.tap.asDriver().drive(viewModel.input.didTapAction).disposed(by: disposeBag)
    cancelButton.rx.tap.asDriver().drive(viewModel.input.didTapCancel).disposed(by: disposeBag)

    //Output
    viewModel.output.message.asDriver(onErrorJustReturn: nil).drive(textLabel.rx.text).disposed(by: disposeBag)

    viewModel.output.description.asDriver(onErrorJustReturn: nil).drive(descLabel.rx.text).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)

    cancelButton.rx.tap.subscribe(onNext: { [weak self] (_) in
      self?.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)
  }

}
