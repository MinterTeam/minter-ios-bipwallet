//
//  CoinAutocompleteCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import UIKit

class CoinAutocompleteCell: LUAutocompleteTableViewCell {

	@IBOutlet weak var coinTitleLabel: UILabel!

	override func set(text: String, searchText: String? = nil) {
		let attributedText = NSMutableAttributedString(string: text,
                                                   attributes: [NSAttributedString.Key.font: UIFont.defaultFont(of: 16.0)])

		if let srch = searchText, let range = attributedText.string.range(of: srch) {

			let nsrange = NSRange(range, in: attributedText.string)
      attributedText.addAttributes([NSAttributedString.Key.font: UIFont.boldFont(of: 16.0)], range: nsrange)
		}

		coinTitleLabel.attributedText = attributedText
	}

}
