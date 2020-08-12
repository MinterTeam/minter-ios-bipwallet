//
//  ModifyContactViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 30/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxBiBinding
import NotificationBannerSwift

class ModifyContactViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView!
  @IBOutlet weak var successView: HandlerVerticalSnapDraggableView!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var address: UITextView!
  @IBOutlet weak var name: UITextField!
  @IBOutlet weak var successTitleLabel: UILabel!
  @IBOutlet weak var closeButtonSuccessViewButton: UIButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ModifyContactViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ModifyContactViewModel) {
    configureDefault()

    //Input
    (address.rx.text <-> viewModel.output.address).disposed(by: disposeBag)
    (name.rx.text <-> viewModel.output.name).disposed(by: disposeBag)
    name.rx.controlEvent(.editingDidEndOnExit).subscribe(viewModel.input.didTapGoButton).disposed(by: disposeBag)

    //Output
    viewModel.output.errorNotification
      .asDriver(onErrorJustReturn: nil)
      .filter({ (notification) -> Bool in
        return nil != notification
      }).drive(onNext: { (notification) in
        let banner = NotificationBanner(title: notification?.title ?? "",
                                        subtitle: notification?.text,
                                        style: .danger)
        banner.show()
      }).disposed(by: disposeBag)

    self.viewModel.output.shakeError.subscribe(onNext: { [weak self] (_) in
      self?.mainView.shakeError(duration: 0.07, repeatCount: 2)
    }).disposed(by: disposeBag)

    self.viewModel.output.showSuccess.subscribe(onNext: { [weak self] (title) in
      self?.showSuccess(title)
    }).disposed(by: disposeBag)

    self.viewModel.output.switchKeybordToTitle.subscribe(onNext: { [weak self] (title) in
      self?.name.becomeFirstResponder()
    }).disposed(by: disposeBag)

    self.viewModel.output.title.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] val in
      self?.mainView.title = val
    }).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func loadView() {
    super.loadView()

    mainView.title = "Edit Address".localized()

    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.rx
      .notification(ViewController.keyboardWillShowNotification)
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height
        self.bottomConstraint?.constant = self.view.bounds.height - (self.view.bounds.height - keyboardHeight) + 8.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
          UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
            self?.view.layoutIfNeeded()
          })
        }
      }).disposed(by: disposeBag)

    closeButtonSuccessViewButton.rx.tap.subscribe(onNext: { [weak self] (_) in
      self?.dismiss(animated: true) {}
    }).disposed(by: disposeBag)

    mainView?.delegate = self
    address.becomeFirstResponder()

    configure(with: viewModel)
  }

  func showSuccess(_ title: String?) {

    print(successTitleLabel.frame)

    successTitleLabel.text = title
    successTitleLabel.setNeedsDisplay()
    successTitleLabel.setNeedsLayout()
    successTitleLabel.layoutIfNeeded()
    print(successTitleLabel.frame)

    view.addSubview(self.successView)

    self.successView.delegate = self
    self.successView.frame = CGRect(x: self.view.bounds.width,
                                    y: self.mainView.frame.minY,
                                    width: self.mainView.bounds.width,
                                    height: successTitleLabel.frame.maxY + 89.0
    )

    UIView.animate(withDuration: 0.25, animations: { [weak self] in
      guard let `self` = self else { return }

      self.successView.frame = CGRect(x: self.mainView.frame.minX, y: self.mainView.frame.minY, width: self.successView.bounds.width, height: self.successView.bounds.height)

      self.mainView.frame = CGRect(x: -self.mainView.bounds.width, y: self.mainView.frame.minY, width: self.mainView.bounds.width, height: self.mainView.bounds.height)

      self.mainView.alpha = 0.0
    }) { [weak self] completed in
      self?.mainView.removeFromSuperview()
    }
  }

}

extension ModifyContactViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? successView else {
      return
    }

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView ?? successView else {
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
