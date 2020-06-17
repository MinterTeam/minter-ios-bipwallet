//
//  UsernameTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift

class UsernameTableViewCellItem: TextViewTableViewCellItem {
  var didTapContacts = PublishSubject<Void>()
}

class UsernameTableViewCell: TextViewTableViewCell {

	var borderLayer: CAShapeLayer?

  @IBOutlet weak var contactsButton: UIButton!

	// MARK: -

	var maxLength = 110

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()

    textView?.superview?.layer.cornerRadius = 8.0
		setDefault()
		activityIndicator?.backgroundColor = .clear
		textView.font = UIFont.mediumFont(of: 16.0)
    textView.autocorrectionType = .no
	}

	@objc
	override func setValid() {
		self.errorTitle.text = ""
	}

	@objc
	override func setInvalid(message: String?) {

		if nil != message {
			self.errorTitle.text = message
		}
	}

	@objc
	override func setDefault() {
		self.errorTitle.text = ""
	}

  // MARK: -

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? UsernameTableViewCellItem else {
      return
    }

    contactsButton.rx.tap.asDriver().drive(item.didTapContacts).disposed(by: disposeBag)
  }

}
