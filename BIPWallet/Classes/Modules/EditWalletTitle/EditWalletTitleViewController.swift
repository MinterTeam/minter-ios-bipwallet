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

class EditWalletTitleViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView! {
    didSet {
      mainView.delegate = self
    }
  }
  @IBOutlet weak var textField: DefaultTextField!

  // MARK: - ControllerProtocol

  typealias ViewModelType = EditWalletTitleViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: EditWalletTitleViewModel) {
    //Input
    (self.textField.rx.text <-> self.viewModel.input.title).disposed(by: disposeBag)

    self.textField.rx
      .controlEvent(.editingDidEnd)
      .subscribe(viewModel.input.didSubmit)
      .disposed(by: disposeBag)

    self.rx.viewWillDisappear
      .asDriver(onErrorJustReturn: true).map { _ in Void() }
      .drive(viewModel.input.willDismiss)
      .disposed(by: disposeBag)

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

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    mainView.title = "Edit Title".localized()

    showBlurOverview { [weak self] in
      self?.dismiss(animated: true) {}
    }

    textField.becomeFirstResponder()

    NotificationCenter
      .default
      .rx
      .notification(ViewController.keyboardWillShowNotification)
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height
        `self`.bottomConstraint.constant = `self`.view.bounds.height - (`self`.view.bounds.height - keyboardHeight) + 8.0
        UIView.animate(withDuration: 0.5) {
          `self`.view.layoutIfNeeded()
        }
      }).disposed(by: disposeBag)

    view.addBackgroundTapGesture { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }

    configure(with: viewModel)
  }

}

extension EditWalletTitleViewController: DraggableViewDelegate {

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
      updateBlurView(percentage: 1.0)
    }
  }
}
