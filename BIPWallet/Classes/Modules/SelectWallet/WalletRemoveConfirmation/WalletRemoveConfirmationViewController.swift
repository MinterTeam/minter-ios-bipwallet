//
//  WalletRemoveConfirmationViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 06/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class WalletRemoveConfirmationViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView!
  @IBOutlet weak var text: UILabel!
  @IBOutlet weak var confirm: UIButton!
  @IBOutlet weak var cancel: UIButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = WalletRemoveConfirmationViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: WalletRemoveConfirmationViewModel) {
    //Input
    confirm.rx.tap.asDriver()
      .drive(viewModel.input.didTapConfirmButton)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.text.asDriver(onErrorJustReturn: nil)
      .drive(text.rx.attributedText)
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }

    cancel.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
      self?.dismiss(animated: true)
    }).disposed(by: disposeBag)

    configure(with: viewModel)
  }

}

extension WalletRemoveConfirmationViewController: DraggableViewDelegate {

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
