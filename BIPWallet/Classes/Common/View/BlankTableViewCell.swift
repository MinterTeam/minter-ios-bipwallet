//
//  BlankTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class BlankTableViewCellItem: BaseCellItem {
	var color: UIColor?
  var height: CGFloat = 10.0
}

class BlankTableViewCell: BaseCell {

	// MARK: -

  @IBOutlet weak var heightConstraint: NSLayoutConstraint!
  @IBOutlet weak var placeholderView: UIView!

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let item = item as? BlankTableViewCellItem {
			self.backgroundColor = item.color
			self.contentView.backgroundColor = item.color
			placeholderView.backgroundColor = item.color
      heightConstraint.constant = item.height
		}
	}
}
