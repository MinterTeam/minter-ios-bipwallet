//
//  TextViewTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import RxBiBinding

protocol TextViewTableViewCellDelegate: class {
	func heightDidChange(cell: TextViewTableViewCell)
	func heightWillChange(cell: TextViewTableViewCell)
  func editingWillEnd(cell: TextViewTableViewCell)
}

class TextViewTableViewCellItem: BaseCellItem {
	var title: String?
	var stateObservable: Observable<TextViewTableViewCell.State>?
	var isLoadingObservable: Observable<Bool>?
	var value: String?
	var keybordType: UIKeyboardType?
	var titleObservable: Observable<String?>?

	var text = BehaviorRelay<String?>(value: nil)
  var didEndEditing = PublishSubject<Void>()
}

class TextViewTableViewCell: BaseCell, AutoGrowingTextViewDelegate {

	enum State {
		case `default`
		case valid
		case invalid(error: String)
	}

	// MARK: -

	weak var delegate: TextViewTableViewCellDelegate?

	// MARK: - IBOutlets

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var errorTitle: UILabel!
	@IBOutlet weak var textView: UITextView! {
		didSet {
			textView.delegate = self
		}
	}
	var activityIndicator: UIActivityIndicatorView?

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()

    self.textView.layer.cornerRadius = 8.0
    activityIndicator = UIActivityIndicatorView(style: .gray)
		activityIndicator?.backgroundColor = .clear
		activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: - BaseCell

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let item = item as? TextViewTableViewCellItem {
			(textView.rx.text <-> item.text).disposed(by: disposeBag)

			self.title.text = item.title

			if let val = item.value {
				self.textView?.text = val
			}
			if let keyboard = item.keybordType {
				self.textView?.keyboardType = keyboard
			}

			item.isLoadingObservable?
				.subscribe(onNext: { [weak self] (val) in
					if val {
						self?.activityIndicator?.startAnimating()
					} else {
						self?.activityIndicator?.stopAnimating()
					}
				}).disposed(by: disposeBag)

			item.stateObservable?
				.subscribe(onNext: { [weak self] (stt) in
					switch stt {
					case .default:
						self?.setDefault()
						break

					case .invalid(let err):
						self?.setInvalid(message: err)
						break

					case .valid:
						self?.setValid()
						break
					}
				}).disposed(by: disposeBag)

			if let textView = textView {
				item.titleObservable?.asDriver(onErrorJustReturn: "")
					.drive(textView.rx.text).disposed(by: disposeBag)
			}
		}
	}

	func textViewDidChangeHeight(_ textView: AutoGrowingTextView, height: CGFloat) {
		delegate?.heightDidChange(cell: self)
	}
  
  func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    delegate?.editingWillEnd(cell: self)
    return true
  }

	// MARK: - Validate

	var validationText: String {
		return textView.text ?? ""
	}
}

extension TextViewTableViewCell: UITextViewDelegate {
	func textViewDidEndEditing(_ textView: UITextView) {}
}

extension TextViewTableViewCell: ValidatableCellProtocol {

	@objc
	func setValid() {
		self.errorTitle.text = ""
	}

	@objc
	func setInvalid(message: String?) {

		if nil != message {
			self.errorTitle.text = message
		}
	}

	@objc
	func setDefault() {
		self.errorTitle.text = ""
	}
}
