//
//  SendPopupViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 18/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SendPopupViewModel: PopupViewModel, ViewModel {
	var input: SendPopupViewModel.Input!
	var output: SendPopupViewModel.Output!
	var dependency: SendPopupViewModel.Dependency!

	struct Input {}
	struct Output {}
	struct Dependency {}

	// MARK: -

	private var formatter = CurrencyNumberFormatter.coinFormatter

	// MARK: -

	override init() {
		super.init()
	}

	// MARK: -

	var amount: Decimal?
	var coin: String?
	var amountString: String? {
    return formatter.formattedDecimal(with: amount ?? 0.0)
	}
	var avatarImageURL: URL?
	var avatarImage: UIImage?
	var username: String?
	var buttonTitle: String?
	var cancelTitle: String?
}
