//
//  ConfirmPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import AlamofireImage
import RxSwift
import RxCocoa

protocol ConfirmPopupViewControllerDelegate: class {
	func didTapActionButton(viewController: ConfirmPopupViewController)
	func didTapSecondButton(viewController: ConfirmPopupViewController)
}

class ConfirmPopupViewController: PopupViewController, Controller, StoryboardInitializable {

	// MARK: -

	var viewModel: ConfirmPopupViewModel!

	typealias ViewModelType = ConfirmPopupViewModel

	func configure(with viewModel: ConfirmPopupViewModel) {
		descLabel.text = viewModel.output.description

    //Output
    viewModel.output.showWallets.subscribe(onNext: { [weak self] data in
      self?.showPicker(data: data) { selected in
        self?.viewModel.input.didSelectWallet.onNext(selected)
      }
    }).disposed(by: disposeBag)

    viewModel.output.selectedWallet
      .asDriver(onErrorJustReturn: nil)
      .drive(walletLabel.rx.text)
      .disposed(by: disposeBag)

		viewModel.output.isActivityIndicatorAnimating
			.asDriver(onErrorJustReturn: false)
			.drive(onNext: { [weak self] (val) in
				self?.actionButton.isEnabled = !val
				self?.actionButtonActivityIndicator.alpha = val ? 1.0 : 0.0
				if val {
					self?.actionButtonActivityIndicator.startAnimating()
          self?.actionButton.setTitle(nil, for: .normal)
				} else {
					self?.actionButtonActivityIndicator.stopAnimating()
				}
			}).disposed(by: disposeBag)

    viewModel.output.activeButtonTitle.asDriver(onErrorJustReturn: nil)
      .drive(actionButton.rx.title(for: .normal))
      .disposed(by: disposeBag)

		//Input
		actionButton.rx.tap.asDriver(onErrorJustReturn: ())
			.drive(viewModel.input.didTapAction)
			.disposed(by: disposeBag)

    self.rx.viewWillAppear.map{_ in}
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)

    self.popupView.dismissable = viewModel.output.dismissable()
	}

	weak var delegate: ConfirmPopupViewControllerDelegate?

	// MARK: - IBOutlet

  @IBOutlet weak var walletView: UIView!
  @IBOutlet weak var walletLabel: UILabel!
	@IBOutlet weak var descLabel: UILabel!
	@IBOutlet weak var actionButtonActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var actionButton: DefaultButton!
  @IBOutlet weak var cancelButton: DefaultButton!

	@IBAction func actionBtnDidTap(_ sender: Any) {
		delegate?.didTapActionButton(viewController: self)
	}

  @IBAction func cancelBtnDidTap(_ sender: Any) {
    delegate?.didTapSecondButton(viewController: self)
  }

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()

    walletView.rx.tapGesture().when(.ended).map { _ in }
      .subscribe(viewModel.input.didTapWallet)
      .disposed(by: disposeBag)

    configure(with: viewModel)

		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: -

	private func updateUI() {
		guard let viewModel = viewModel else {
			return
		}
		self.actionButton.setTitle(viewModel.buttonTitle, for: .normal)
//		self.secondButton.setTitle(viewModel.cancelTitle, for: .normal)
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

  // MARK: -

}
