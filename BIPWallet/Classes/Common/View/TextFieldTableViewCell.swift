//
//  TextFieldTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxBiBinding

class TextFieldTableViewCellItem: BaseCellItem {
	var title: String = ""
	var isSecure: Bool = false
	var prefix: String?
	var state: TextFieldTableViewCell.State?
	var error: String?
	var value: String?
	var keyboardType: UIKeyboardType?
	var stateObservable: Observable<TextFieldTableViewCell.State>?
	var isLoadingObservable: Observable<Bool>?

	var text = BehaviorRelay<String?>(value: nil)
}

class TextFieldTableViewCell: BaseCell, ValidatableCellProtocol {

	// MARK: -

	enum State {
		case valid
		case invalid(error: String?)
		case `default`
	}

	var state: State = .default {
		didSet {
			switch state {

			case .valid:
				textField.layer.cornerRadius = 8.0
//				textField.layer.borderWidth = 2
//				textField.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
				textField.rightView = textField.rightViewValid
				textField.rightViewMode = .always
				errorTitle.text = ""
				break

			case .invalid(let error):
				textField.layer.cornerRadius = 8.0
//				textField.layer.borderWidth = 2
//        textField.layer.borderColor = UIColor.mainRedColor().cgColor
				textField.rightView = textField.rightViewInvalid
				textField.rightViewMode = .always
				if nil != error {
					self.errorTitle.text = error
				}
				break

			default:
				textField.layer.cornerRadius = 8.0
//				textField.layer.borderWidth = 2
//        textField.layer.borderColor = UIColor.mainGreyColor(alpha: 0.4).cgColor
				textField.rightView = UIView()
				textField.rightViewMode = .never
				errorTitle.text = ""
				break
			}
		}
	}

	// MARK: -

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var errorTitle: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var textField: ValidatableTextField!

	// MARK: - Validators

	var validationText: String {
		return textField.text ?? ""
	}

	// MARK: - BaseCell

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let item = item as? TextFieldTableViewCellItem {
			(textField.rx.text <-> item.text).disposed(by: disposeBag)

			title.text = item.title
			textField.isSecureTextEntry = item.isSecure
			textField.prefixText = item.prefix
			if let val = item.value {
				textField.text = val
			}

			if let keyboard = item.keyboardType {
				textField.keyboardType = keyboard
			}

			state = item.state ?? .default
//			validatorRules = item.rules
			errorTitle.text = item.error

			item.stateObservable?.share().asObservable()
				.subscribe(onNext: { (state) in
				switch state {
				case .default:
					self.setDefault()
					break
				case .valid:
					self.setValid()
					break
				case .invalid(let err):
					self.setInvalid(message: err)
					break
				}
			}).disposed(by: disposeBag)

			activityIndicator?.isHidden = true
			item.isLoadingObservable?.asObservable().distinctUntilChanged()
				.subscribe(onNext: { [weak self] (isLoading) in
					if isLoading {
						self?.activityIndicator.startAnimating()
						self?.activityIndicator.isHidden = false
					} else {
						self?.activityIndicator.stopAnimating()
						self?.activityIndicator.isHidden = true
					}
			}).disposed(by: disposeBag)

			textField?
				.rx
				.text
				.orEmpty
				.asObservable()
				.distinctUntilChanged()
				.subscribe(onNext: { [weak self] (val) in
					self?.validateDelegate?.validate(field: self, completion: {})
				}).disposed(by: disposeBag)
		}
	}

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
		state = .default
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		state = .default
		layoutIfNeeded()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
	}

	// MARK: -

	func startEditing() {
		self.textField.becomeFirstResponder()
	}

	// MARK: - ValidatableCellProtocol

	weak var validateDelegate: ValidatableCellDelegate?

	func setValid() {
		self.state = .valid
		self.errorTitle.text = ""
	}

	func setInvalid(message: String?) {
		self.state = .invalid(error: message)
		if nil != message {
			self.errorTitle.text = message
		}
	}

	func setDefault() {
		self.state = .default
		self.errorTitle.text = ""
	}
}

extension TextFieldTableViewCell: UITextFieldDelegate {
	func textFieldDidEndEditing(_ textField: UITextField) {
		validateDelegate?.didValidateField(field: self)
		self.layoutIfNeeded()
	}
}
