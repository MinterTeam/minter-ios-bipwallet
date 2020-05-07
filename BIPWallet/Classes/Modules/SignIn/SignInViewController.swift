//
//  SignInViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxBiBinding
import RxAppState

class SignInViewController: BaseViewController, Controller, StoryboardInitializable, UIImpactFeedbackProtocol {

  // MARK: -

  @IBOutlet weak var mainViewLoaderView: UIView!
  @IBOutlet weak var activateButtonActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView! {
    didSet {
      mainView.delegate = self
    }
  }
  @IBOutlet weak var textView: DefaultTextView! {
    didSet {
      textView.setPlaceholder(" Your seed phrase…")
    }
  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = SignInViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SignInViewModel) {
    //Input
    self.rx.viewDidDisappear
      .asDriver(onErrorJustReturn: true)
      .drive(viewModel.input.viewDidDisappear)
      .disposed(by: disposeBag)

    (self.textView.rx.text <-> self.viewModel.output.mnemonics).disposed(by: disposeBag)

    self.textView.rx.text.do(onNext: { (val) in
      if val?.contains("\n") ?? false {
        self.viewModel.input.didTapGo.onNext(())
      }
    }).scan("") { prev, new in
      if new?.contains("\n") ?? false {
        return new?.replacingOccurrences(of: "\n", with: "") ?? ""
      } else {
        return new ?? ""
      }
    }.subscribe(self.textView.rx.text).disposed(by: disposeBag)

    //Output
    self.viewModel.output.title
      .asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] (title) in
        self?.mainView.title = title
    }).disposed(by: disposeBag)

    self.viewModel.output.errorMessage.subscribe(onNext: { (message) in
      BannerHelper.performErrorNotification(title: message, subtitle: nil)
    }).disposed(by: disposeBag)

    self.viewModel.output.hardImpact.subscribe(onNext: { [weak self] (_) in
      self?.hardImpactFeedbackGenerator.prepare()
      self?.hardImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    self.viewModel.output.shakeError.subscribe(onNext: { [weak self] (_) in
      self?.mainView.shakeError(duration: 0.07, repeatCount: 2)
    }).disposed(by: disposeBag)
    
    viewModel.output.isLoading.distinctUntilChanged().asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] val in
      UIView.animate(withDuration: 0.25) {
        self?.mainViewLoaderView?.alpha = val ? 1.0 : 0.0
        self?.activateButtonActivityIndicator.alpha = val ? 1.0 : 0.0
      }
    }).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.rx.notification(ViewController.keyboardWillShowNotification)
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height
        self.bottomConstraint.constant = self.view.bounds.height - (self.view.bounds.height - keyboardHeight) + 8.0
        UIView.animate(withDuration: 0.5) {
          self.view.layoutIfNeeded()
        }
      }).disposed(by: disposeBag)

    showBlurOverview { [weak self] in
      self?.textView.endEditing(true)
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }

    configure(with: viewModel)

    self.textView.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    self.textView.endEditing(true)
  }

}

extension SignInViewController: DraggableViewDelegate {

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

