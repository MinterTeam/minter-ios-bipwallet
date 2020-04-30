//
//  SendPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 18/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage

protocol SendPopupViewControllerDelegate: class {
	func didFinish(viewController: SendPopupViewController)
	func didCancel(viewController: SendPopupViewController)
}

class SendPopupViewController: PopupViewController, Controller, StoryboardInitializable {

	// MARK: -

	typealias ViewModelType = SendPopupViewModel
	var viewModel: SendPopupViewModel!
	func configure(with viewModel: SendPopupViewModel) {

	}

	// MARK: -

	weak var delegate: SendPopupViewControllerDelegate?

	// MARK: - IBOutlet
	@IBOutlet weak var amountTitle: UILabel!
	@IBOutlet weak var userLabel: UILabel!
	@IBOutlet weak var actionButton: DefaultButton!
	@IBOutlet weak var cancelButton: DefaultButton!
	@IBOutlet weak var acitionButtonActivityIndicator: UIActivityIndicatorView!
	@IBAction func secondButtonDidTap(_ sender: UIButton) {
		self.delegate?.didCancel(viewController: self)
	}
	@IBAction func didTapActionButton(_ sender: UIButton) {
		acitionButtonActivityIndicator?.startAnimating()
		acitionButtonActivityIndicator?.alpha = 1.0
		sender.isEnabled = false
    sender.setTitle("", for: .normal)
		self.delegate?.didFinish(viewController: self)
	}

	// MARK: -

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		hidesBottomBarWhenPushed = true
	}

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

//		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinPopupScreen, params: nil)
	}

	override func loadView() {
		super.loadView()
		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: -

	private func updateUI() {
		popupTitle.text = viewModel?.popupTitle

		amountTitle.text = String((viewModel?.amountString ?? "") + " " + (viewModel?.coin ?? "")).uppercased()

		userLabel.text = viewModel?.username
		actionButton.setTitle(viewModel?.buttonTitle ?? "", for: .normal)
		cancelButton.setTitle(viewModel?.cancelTitle ?? "", for: .normal)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}
}
