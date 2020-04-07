//
//  SignInViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
//import RxViewController
import RxBiBinding
import RxAppState

class SignInViewController: BaseViewController, Controller, StoryboardInitializable, UIImpactFeedbackProtocol {

  // MARK: - UIImpactFeedbackProtocol

  var hardImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  // MARK: -

  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView!
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

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("viewWillAppear")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    print("viewWillDisappear")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("viewDidAppear")
    self.textView.becomeFirstResponder()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    print("viewDidDisappear")
  }

}
