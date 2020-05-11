//
//  DelegateUnbondViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture
import RxBiBinding

class DelegateUnbondViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet
  
  var isDragging = false

  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var validatorView: UIView!
  @IBOutlet weak var validatorTitle: UILabel!
  @IBOutlet weak var validatorPublicKey: UILabel!
  @IBOutlet weak var coinTextField: DefaultTextField! {
    didSet {
      coinTextField.delegate = self
    }
  }
  @IBOutlet weak var amountTextField: ValidatableTextField!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var useMaxButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = DelegateUnbondViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: DelegateUnbondViewModel) {
    configureDefault()

    //Output
    viewModel.output.fee.asDriver(onErrorJustReturn: "").drive(feeLabel.rx.text).disposed(by: disposeBag)

    viewModel.output.showValidators.subscribe(onNext: { [weak self] data in
      self?.showPicker(data: data) { selected in
        self?.viewModel.input.didSelectValidator.onNext(selected)
      }
    }).disposed(by: disposeBag)

    viewModel.output.showCoins.subscribe(onNext: { [weak self] data in
      self?.showPicker(data: data) { selected in
        self?.viewModel.input.didSelectCoin.onNext(selected)
      }
    }).disposed(by: disposeBag)

    viewModel.output.isLoading.asDriver(onErrorJustReturn: false)
      .drive(onNext: { (val) in
        if val {
          self.activityIndicator.isHidden = false
          self.activityIndicator.startAnimating()
        } else {
          self.activityIndicator.isHidden = true
          self.activityIndicator.stopAnimating()
        }
      }).disposed(by: disposeBag)

    viewModel.output.buttonTitle.asDriver(onErrorJustReturn: "")
      .drive(sendButton.rx.title(for: .normal))
      .disposed(by: disposeBag)

    viewModel.output.title.asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] val in
        self?.mainView.title = val
      })
      .disposed(by: disposeBag)

    viewModel.output.isButtonEnabled.asDriver(onErrorJustReturn: false)
      .drive(sendButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.output.successMessage.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] (message) in
      BannerHelper.performSuccessNotification(title: message, subtitle: nil)
      self?.lightImpactFeedbackGenerator.prepare()
      self?.lightImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    viewModel.output.errorMessage.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] (message) in
      BannerHelper.performErrorNotification(title: message, subtitle: nil)
      self?.hardImpactFeedbackGenerator.prepare()
      self?.hardImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    viewModel.output.validatorPublicKey.asDriver(onErrorJustReturn: "")
      .drive(validatorPublicKey.rx.text).disposed(by: disposeBag)

    viewModel.output.validatorName.asDriver(onErrorJustReturn: "")
      .drive(validatorTitle.rx.text).disposed(by: disposeBag)

    viewModel.output.description.asDriver(onErrorJustReturn: nil)
      .drive(descriptionLabel.rx.text)
      .disposed(by: disposeBag)

    //Input
    validatorView.rx.tapGesture().when(.ended).map {_ in Void() }
      .subscribe(viewModel.input.didTapValidator)
      .disposed(by: disposeBag)

    coinTextField.rx.tapGesture().when(.ended).map {_ in Void() }
      .subscribe(viewModel.input.didTapCoin)
      .disposed(by: disposeBag)

    (amountTextField.rx.text <-> viewModel.input.amount).disposed(by: disposeBag)
    (coinTextField.rx.text <-> viewModel.input.coin).disposed(by: disposeBag)

    let buttonTap = sendButton.rx.tap.asDriver()
    buttonTap.drive(viewModel.input.didTapSend).disposed(by: disposeBag)
    buttonTap.drive(onNext: { [weak self] (_) in
      self?.amountTextField.endEditing(true)
    }).disposed(by: disposeBag)

    useMaxButton.rx.tap.asDriver()
      .drive(viewModel.input.didTapUseMax)
      .disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    mainView?.delegate = self

    amountTextField.rightPadding = CGFloat(self.useMaxButton.bounds.width)

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

        if !self.isDragging {

          UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
          }
        }
      }).disposed(by: disposeBag)

    Observable.merge(validatorView.rx.tapGesture().when(.ended), coinTextField.rx.tapGesture().when(.ended)).subscribe(onNext: { [weak self] (_) in
      self?.amountTextField.endEditing(true)
    }).disposed(by: disposeBag)

    configure(with: viewModel)
  }

  override func loadView() {
    super.loadView()

    mainView.title = "Delegate".localized()

    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }
  }

  func showPicker(data: [[String]], completion: (([Int: String]) -> ())?) {
    let picker = McPicker(data: data)
    picker.toolbarButtonsColor = .white
    picker.toolbarDoneButtonColor = .white
    picker.toolbarBarTintColor = UIColor.mainPurpleColor()
    picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
    picker.show { [weak self] (selected) in
      completion?(selected)
    }
  }

}

extension DelegateUnbondViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }
    
    isDragging = true

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    if percentage < 0.8 {
      amountTextField.endEditing(true)
    }

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }

    isDragging = false

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

extension DelegateUnbondViewController: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return false
  }

}
