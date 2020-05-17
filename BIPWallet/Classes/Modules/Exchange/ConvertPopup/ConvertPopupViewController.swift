//
//  ConvertPopupViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class ConvertPopupViewController: PopupViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var loadingView: PopupLoadingView!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ConvertPopupViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ConvertPopupViewModel) {
    //Input
    actionButton.rx.tap.asDriver().drive(viewModel.input.actionDidTap).disposed(by: disposeBag)
    cancelButton.rx.tap.asDriver().drive(viewModel.input.cancelDidTap).disposed(by: disposeBag)
    //Output
    viewModel.output.fromText.asDriver(onErrorJustReturn: nil).drive(fromTextLabel.rx.text).disposed(by: disposeBag)
    viewModel.output.toText.asDriver(onErrorJustReturn: nil).drive(toTextLabel.rx.text).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.popupViewControllerDelegate = self

    configure(with: viewModel)

    actionButton.rx.tap.subscribe(onNext: { [weak self] (_) in
      self?.contentViewHeightConstraint.constant = (self?.loadingView.bounds.height ?? 0.0) + 16.0
      self?.contentViewHeightConstraint.isActive = true
      self?.popupTitle.text = "Exchanging".localized()
      self?.loadingView.startAnimating()
      self?.popupView.dismissable = false
      UIView.animate(withDuration: 0.5, animations: {
        self?.view.layoutIfNeeded()
        self?.loadingView.alpha = 1.0
        self?.contentView.alpha = 0.0
        self?.contentView.frame = CGRect(x: 0,
                                         y: self?.loadingView.frame.minY ?? 0.0,
                                         width: self?.loadingView.bounds.width ?? 0.0,
                                         height: self?.loadingView.bounds.height ?? 0.0)
      }) { (compl) in
        self?.contentView.removeFromSuperview()
      }

    }).disposed(by: disposeBag)

    cancelButton.rx.tap.subscribe(onNext: { [weak self] (_) in
      self?.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)
  }

}

extension ConvertPopupViewController: PopupViewControllerDelegate {

  func didDismissPopup(viewController: PopupViewController?) {
    if contentView.superview != nil {
      self.dismiss(animated: true, completion: nil)
    }
  }

}
