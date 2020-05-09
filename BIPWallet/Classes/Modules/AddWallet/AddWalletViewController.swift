//
//  AddWalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState
import SnapKit
import RxBiBinding

class AddWalletViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - Outlets

  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var mnemonicTextView: DefaultTextView!
  @IBOutlet weak var titleError: UILabel!
  @IBOutlet weak var titleTextField: DefaultTextField!
  //Generate mnemonic
  @IBOutlet weak var generateTitleError: UILabel!
  @IBOutlet weak var generateTitleTextField: DefaultTextField!
  @IBOutlet weak var generateView: HandlerVerticalSnapDraggableView! {
    didSet {
      generateView.title = "Generate New Wallet"
    }
  }
  var generateViewBottomConstraint: Constraint!
  @IBOutlet weak var generateWalletButton: DefaultButton!

  @IBOutlet weak var activateButtonActivityIndicator: UIActivityIndicatorView!

  @IBOutlet weak var mainViewLoaderView: UIView!
  @IBOutlet weak var copiedIndicator: UIView!
  @IBOutlet weak var savedSwitch: UISwitch!
  @IBOutlet weak var mnemonicLabel: UILabel!
  @IBOutlet weak var mnemonicError: UILabel!
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
      mainView.title = "Add New Wallet"
      mainView.delegate = self
    }
  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = AddWalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: AddWalletViewModel) {
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

    (mnemonicTextView.rx.text <-> viewModel.input.signInMnemonics).disposed(by: disposeBag)
    (titleTextField.rx.text <-> viewModel.input.signInTitle).disposed(by: disposeBag)
    titleTextField.rx.controlEvent(.editingDidEndOnExit).subscribe(viewModel.input.titleDidEndEditing).disposed(by: disposeBag)

    (generateTitleTextField.rx.text <-> viewModel.input.title).disposed(by: disposeBag)

    //Output
    viewModel.output.mnemonics
      .asDriver(onErrorJustReturn: "")
      .drive(mnemonicLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.isButtonEnabled
      .asDriver(onErrorJustReturn: false)
      .drive(activateButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.output.errorMessage.subscribe(onNext: { (message) in
      BannerHelper.performErrorNotification(title: message, subtitle: nil)
    }).disposed(by: disposeBag)

    viewModel.output.hardImpact.subscribe(onNext: { [weak self] (_) in
      self?.hardImpactFeedbackGenerator.prepare()
      self?.hardImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    viewModel.output.shakeError.subscribe(onNext: { [weak self] (_) in
      self?.mainView?.shakeError(duration: 0.07, repeatCount: 2)
    }).disposed(by: disposeBag)

    viewModel.output.buttonTitle
      .asDriver(onErrorJustReturn: nil)
      .drive(activateButton.rx.title(for: .disabled))
      .disposed(by: disposeBag)

    viewModel.output.isLoading.subscribe(onNext: { [weak self] (val) in
      if val {
        self?.activateButtonActivityIndicator.startAnimating()
      } else {
        self?.activateButtonActivityIndicator.stopAnimating()
      }

      UIView.animate(withDuration: 0.25) {
        self?.mainViewLoaderView?.alpha = val ? 1.0 : 0.0
        self?.activateButtonActivityIndicator.alpha = val ? 1.0 : 0.0
      }
    }).disposed(by: disposeBag)

    viewModel.output.titleError.asDriver(onErrorJustReturn: nil)
      .drive(titleError.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.titleError.asDriver(onErrorJustReturn: nil)
      .drive(generateTitleError.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.mnemonicsError.asDriver(onErrorJustReturn: nil)
      .drive(mnemonicError.rx.text)
      .disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    generateView.alpha = 0.0
    view.addSubview(self.generateView)
    generateView.snp.makeConstraints { (maker) in
      self.generateViewBottomConstraint = maker.bottom.equalTo(self.view).offset(-34).constraint
      maker.leading.equalTo(self.view).offset(8)
      maker.trailing.equalTo(self.view).offset(-8)
    }

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

    Observable<Notification>.merge(NotificationCenter.default.rx.notification(ViewController.keyboardWillShowNotification),
                                   NotificationCenter.default.rx.notification(ViewController.keyboardWillHideNotification))
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height
        var bottomPadding = self.view.bounds.height - (self.view.bounds.height - keyboardHeight) + 8.0

        if ViewController.keyboardWillHideNotification == not.name {
          bottomPadding = 34
        }

        self.bottomConstraint?.constant = bottomPadding
        self.generateViewBottomConstraint.updateOffset(amount: -bottomPadding)
        UIView.animate(withDuration: 0.5) {
          self.view.layoutIfNeeded()
        }
      }).disposed(by: disposeBag)

    generateWalletButton.rx.tap.subscribe(onNext: { (_) in
      self.showGenerate(nil)
    }).disposed(by: disposeBag)
  }

  override func loadView() {
    super.loadView()
    
    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }
  }

  func showGenerate(_ title: String?) {
    self.generateView.alpha = 1.0
    self.generateView.delegate = self

    let generateViewY = self.view.bounds.height - self.generateView.bounds.height - 34
    self.generateView.frame = CGRect(x: self.view.bounds.width,
                                     y: generateViewY,
                                     width: self.generateView.bounds.width,
                                     height: self.generateView.bounds.height)
    UIView.animate(withDuration: 0.25, animations: { [weak self] in
      guard let `self` = self else { return }
      self.generateView.frame = CGRect(x: self.mainView.frame.minX,
                                       y: generateViewY,
                                       width: self.generateView.bounds.width,
                                       height: self.generateView.bounds.height)
      self.mainView.frame = CGRect(x: -self.mainView.bounds.width,
                                   y: self.mainView.frame.minY,
                                   width: self.mainView.bounds.width,
                                   height: self.mainView.bounds.height)
      self.mainView.alpha = 0.0
    }) { [weak self] completed in
      self?.mainView.removeFromSuperview()
    }
  }

}

extension AddWalletViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? generateView else {
      return
    }

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? generateView else {
      return
    }

    targetView.panGestureDidEnd(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)

    let percentage = translation.y/targetView.bounds.height

    if percentage >= 0.75 {
      updateBlurView(percentage: 0.0)
      self.dismiss(animated: true) {}
    } else {
      updateBlurView(percentage: 1.0)
    }
  }
}
