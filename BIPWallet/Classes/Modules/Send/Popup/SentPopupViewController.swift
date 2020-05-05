//
//  SentViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage

protocol SentPopupViewControllerDelegate: class {
	func didTapActionButton(viewController: SentPopupViewController)
	func didTapSecondActionButton(viewController: SentPopupViewController)
	func didTapSecondButton(viewController: SentPopupViewController)
}

class SentPopupViewController: PopupViewController, Controller, StoryboardInitializable {

	// MARK: -

	typealias ViewModelType = SentPopupViewModel

	var viewModel: SentPopupViewModel!

	func configure(with viewModel: SentPopupViewModel) {

	}

	weak var delegate: SentPopupViewControllerDelegate?

	// MARK: -

	@IBOutlet weak var descTitle: UILabel!
	@IBOutlet weak var receiverLabel: UILabel!
	@IBOutlet weak var actionButton: DefaultButton!
	@IBOutlet weak var seconActionButton: DefaultButton!
	@IBOutlet weak var secondButton: DefaultButton!

	@IBAction func actionBtnDidTap(_ sender: Any) {
		delegate?.didTapActionButton(viewController: self)
	}

	@IBAction func secondButtonDidTap(_ sender: Any) {
		delegate?.didTapSecondButton(viewController: self)
	}

	@IBAction func secondActionButtonDidTap(_ sender: Any) {
		delegate?.didTapSecondActionButton(viewController: self)
	}

	// MARK: -

	var shadowLayer = CAShapeLayer()

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		updateUI()
	}

	// MARK: -

	private func updateUI() {

		self.receiverLabel.text = viewModel.username
		if let desc = viewModel.desc {
			descTitle.text = desc
		}
		self.actionButton.setTitle(viewModel.actionButtonTitle, for: .normal)
		self.secondButton.setTitle(viewModel.secondButtonTitle, for: .normal)
	}

	// MARK: -

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}
}
