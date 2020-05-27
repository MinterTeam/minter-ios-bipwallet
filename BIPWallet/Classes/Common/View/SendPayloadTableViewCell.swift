//
//  SendPayloadTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 12/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendPayloadTableViewCellItem: TextViewTableViewCellItem {
  var didTapAddMessage = PublishSubject<Void>()
}

class SendPayloadTableViewCell: TextViewTableViewCell {

  // MARK: -

	var borderLayer: CAShapeLayer?

	// MARK: - IBOutlets

  @IBOutlet weak var addMessageButton: UIButton!
  @IBOutlet weak var payloadView: UIView!
  @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  
	// MARK: -

	var maxLength = 110

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		activityIndicator?.backgroundColor = .clear
		textView.font = UIFont.mediumFont(of: 16.0)
    payloadView.alpha = 0.0
    textView?.superview?.layer.cornerRadius = 8.0
		setDefault()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	override func textViewDidEndEditing(_ textView: UITextView) {
//		validateDelegate?.didValidateField(field: self)
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

    if let item = item as? SendPayloadTableViewCellItem {
      addMessageButton.rx.tap.subscribe(onNext: { [weak self] (_) in
        self?.textView.becomeFirstResponder()
        self?.addMessageButton.alpha = 0.0
        self?.payloadView.alpha = 1.0
        self?.textViewHeightConstraint?.isActive = false
        self?.setNeedsLayout()
        self?.layoutIfNeeded()
      }).disposed(by: disposeBag)

      cancelButton.rx.tap.subscribe(onNext: { [weak self] (_) in
        self?.textView.resignFirstResponder()
        self?.textViewHeightConstraint?.isActive = true
        self?.textView.text = ""
        UIView.animate(withDuration: 0.5) {
          self?.addMessageButton.alpha = 1.0
          self?.payloadView.alpha = 0.0

          self?.setNeedsLayout()
          self?.layoutIfNeeded()
        }
      }).disposed(by: disposeBag)

      addMessageButton.rx.tap.asDriver()
        .drive(item.didTapAddMessage).disposed(by: disposeBag)
    }
  }

}
