//
//  EditWalletTitleViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 09/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxBiBinding
import SnapKit

class EditWalletTitleViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var confirmationView: HandlerVerticalSnapDraggableView! {
    didSet {
      confirmationView.delegate = self
    }
  }
  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView! {
    didSet {
      mainView.delegate = self
    }
  }
  @IBOutlet weak var textField: DefaultTextField!
  @IBOutlet weak var saveButton: DefaultButton!
  @IBOutlet weak var removeButton: DefaultButton!
  @IBOutlet weak var removeButtonBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var confirmRemoveButton: DefaultButton!
  @IBOutlet weak var confirmCancelButton: DefaultButton!
  @IBOutlet weak var confirmText: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = EditWalletTitleViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: EditWalletTitleViewModel) {
    configureDefault()

    //Input
    (self.textField.rx.text <-> self.viewModel.input.title).disposed(by: disposeBag)

    self.rx.viewWillDisappear
      .asDriver(onErrorJustReturn: true).map{_ in}
      .drive(viewModel.input.willDismiss)
      .disposed(by: disposeBag)

    self.saveButton.rx.tap.asDriver().drive(viewModel.input.didTapSave).disposed(by: disposeBag)

    self.textField.rx.controlEvent(.editingDidEndOnExit).asDriver().map{_ in}
      .drive(viewModel.input.didTapSave).disposed(by: disposeBag)

    Observable.of(self.saveButton.rx.tap.map{_ in},
                  self.textField.rx.controlEvent(.editingDidEndOnExit).map{_ in}).merge()
      .subscribe(onNext: { [weak self] (_) in
        self?.textField.resignFirstResponder()
      }).disposed(by: disposeBag)

    self.confirmRemoveButton.rx.tap.asDriver().drive(viewModel.input.didTapRemove).disposed(by: disposeBag)

    //Output
    self.viewModel.output
      .errorMessage
      .asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] (message) in
        BannerHelper.performErrorNotification(title: message, subtitle: nil)
        self?.textField.becomeFirstResponder()
      }).disposed(by: disposeBag)

    self.viewModel.output.hardImpact.subscribe(onNext: { [weak self] (_) in
      self?.hardImpactFeedbackGenerator.prepare()
      self?.hardImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    self.viewModel.output.shakeError.subscribe(onNext: { [weak self] (_) in
      self?.mainView.shakeError(duration: 0.07, repeatCount: 2)
    }).disposed(by: disposeBag)

    self.viewModel.output.shouldHideRemoveButton.subscribe(onNext: { [weak self] shouldHide in
      if shouldHide {
        self?.removeButton.isHidden = true
        self?.removeButtonBottomConstraint?.constant = -50
      }
    }).disposed(by: disposeBag)

    viewModel.output.text.asDriver(onErrorJustReturn: nil)
      .drive(confirmText.rx.attributedText).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    mainView.title = "Edit Title".localized()

    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }

    textField.becomeFirstResponder()

    NotificationCenter.default.rx
      .notification(ViewController.keyboardWillShowNotification)
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height
        self.bottomConstraint?.constant = self.view.bounds.height - (self.view.bounds.height - keyboardHeight) + 8.0
        UIView.animate(withDuration: 0.5) {
          self.view.layoutIfNeeded()
        }
      }).disposed(by: disposeBag)

    removeButton.rx.tap.asDriver().drive(onNext: { (_) in
      self.view.addSubview(self.confirmationView)
      self.showConfirmation("Remove Wallet")
    }).disposed(by: disposeBag)

    confirmCancelButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
      self?.updateBlurView(percentage: 0.0)
      self?.dismiss(animated: true) {}
    }).disposed(by: disposeBag)

    configure(with: viewModel)

    setNeedsStatusBarAppearanceUpdate()
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  func showConfirmation(_ title: String?) {
    self.confirmationView.alpha = 1.0
    self.confirmationView.delegate = self

    let frame = self.mainView.frame

    self.confirmationView.frame = CGRect(x: self.view.bounds.width,
                                         y: frame.minY,
                                         width: self.mainView.bounds.width,
                                         height: self.confirmationView.bounds.height)

    self.confirmationView.snp.makeConstraints { (maker) in
      maker.width.equalToSuperview().offset(-16)
      maker.leading.equalToSuperview().offset(self.view.bounds.width)
      maker.top.equalTo(frame.minY)
    }

    self.view.layoutIfNeeded()

    UIView.animate(withDuration: 0.25, animations: { [weak self] in
      guard let `self` = self else { return }
      self.confirmationView.frame = CGRect(x: frame.minX,
                                           y: frame.minY,
                                           width: self.confirmationView.bounds.width,
                                           height: self.confirmationView.bounds.height)

      self.confirmationView.snp_updateConstraints { (maker) in
        maker.leading.equalToSuperview().offset(8)
      }

      self.mainView.frame = CGRect(x: -self.mainView.bounds.width,
                                   y: frame.minY,
                                   width: self.mainView.bounds.width,
                                   height: self.mainView.bounds.height)
      self.mainView.alpha = 0.0
    }) { [weak self] completed in
      self?.mainView.removeFromSuperview()
    }
  }

}

extension EditWalletTitleViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? confirmationView else {
      return
    }

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? confirmationView else {
      return
    }

    targetView.panGestureDidEnd(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)

    let percentage = translation.y/targetView.bounds.height

    if percentage >= 0.5 {
      updateBlurView(percentage: 0.0)
      self.dismiss(animated: true) {}
    } else {
      updateBlurView(percentage: 1.0)
    }
  }
}
