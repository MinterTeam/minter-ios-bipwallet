//
//  CreateWalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState

class CreateWalletViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - Outlets

  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var copiedIndicator: UIView!
  @IBOutlet weak var savedSwitch: UISwitch!
  @IBOutlet weak var mnemonicLabel: UILabel!
  @IBOutlet weak var mnemonicButton: UIButton!
  @IBOutlet weak var mnemonicWrapper: UIView! {
    didSet {
      mnemonicWrapper.layer.cornerRadius = 8
      mnemonicWrapper.layer.borderColor = UIColor(hex: 0xE0DAF4)?.cgColor
      mnemonicWrapper.layer.borderWidth = 1
    }
  }
  @IBOutlet weak var activateButton: DefaultButton!
  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView! {
    didSet {
      mainView.title = "Create Wallet"
      mainView?.delegate = self
    }
  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = CreateWalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: CreateWalletViewModel) {
    // Input
    self.rx.viewDidDisappear
      .asDriver(onErrorJustReturn: true)
      .drive(viewModel.input.viewDidDisappear)
      .disposed(by: disposeBag)

    savedSwitch.rx.isOn
      .asDriver()
      .drive(viewModel.input.isSwichOn)
      .disposed(by: disposeBag)

    activateButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapActivate)
      .disposed(by: disposeBag)

    mnemonicButton.rx.tap.asDriver()
      .drive(viewModel.input.didTapMnemonic)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.mnemonic
      .asDriver(onErrorJustReturn: "")
      .drive(mnemonicLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.isButtonEnabled
      .asDriver(onErrorJustReturn: false)
      .drive(activateButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.output.isLoading.asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (isLoading) in
        if isLoading {
          self?.activityIndicator.startAnimating()
          self?.activateButton.isEnabled = false
        } else {
          self?.activityIndicator.stopAnimating()
        }
        self?.activityIndicator.isHidden = !isLoading
      }).disposed(by: disposeBag)

    viewModel.output.buttonTitle
      .asDriver(onErrorJustReturn: "")
      .drive(activateButton.rx.title(for: .disabled)).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    activateButton.isEnabled = false

    configure(with: viewModel)

    mnemonicButton.rx.tap.subscribe(onNext: { [weak self] (_) in
      self?.mnemonicButton.isEnabled = false

      UIView.animate(withDuration: 0.25, animations: {
        self?.copiedIndicator.alpha = 1.0
      }) { (suc) in
        self?.mnemonicButton.isEnabled = true
        UIView.animate(withDuration: 0.25,
                       delay: 3,
                       options: [.curveEaseInOut],
                       animations: {

          self?.copiedIndicator.alpha = 0.0
        }) { (succ) in

        }
      }
    }).disposed(by: disposeBag)

    showBlurOverview { [weak self] in
      self?.dismiss(animated: true) {}
    }
  }

}

extension CreateWalletViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }

    targetView.panGestureDidEnd(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)

    let percentage = translation.y/targetView.bounds.height

    if percentage >= 0.75 {
      updateBlurView(percentage: 0.0)
      self.dismiss(animated: true) {}
    } else {
      UIView.animate(withDuration: 0.25) {
        self.view.setNeedsLayout()
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
      }
      updateBlurView(percentage: 1.0)
    }
  }
}
