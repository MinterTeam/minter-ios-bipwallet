//
//  BUttonTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol ButtonTableViewCellDelegate: class {
	func buttonTableViewCellDidTap(_ cell: ButtonTableViewCell)
}

class ButtonTableViewCellItem: BaseCellItem {

	// MARK: - I/O

	struct Input {
		var didTapButton: AnyObserver<Void>
	}

	struct Output {
		var didTapButton: Observable<Void>
	}

	var input: Input?
	var output: Output?

	// MARK: - Subjects

	let didTapButtonSubject = PublishSubject<Void>()
//  var buttonTitleObservable = PublishSubject<String?>()

	// MARK: -

	var title: String?
	var buttonPattern: String?
  var buttonColor: String?
	var isButtonEnabled = true
	var isButtonEnabledObservable: Observable<Bool>?
	var isLoadingObserver: Observable<Bool>?
  var buttonTitleObservable: Observable<String?>?

	override init(reuseIdentifier: String, identifier: String) {
		super.init(reuseIdentifier: reuseIdentifier, identifier: identifier)

    input = Input(didTapButton: didTapButtonSubject.asObserver()
//                  buttonTitle: buttonTitleObservable.asObserver()
    )

		output = Output(didTapButton: didTapButtonSubject.asObservable()
//                    buttonTitle: buttonTitleObservable.asObservable()
    )

	}
}

class ButtonTableViewCell: BaseCell {

  // MARK: - Init

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

	// MARK: -

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var button: DefaultButton!

  // MARK: -

  func customizeUI() {
    
  }

	// MARK: - IBActions

	@IBAction func buttonDidTap(_ sender: Any) {
		delegate?.buttonTableViewCellDidTap(self)
	}

	// MARK: -

	weak var delegate: ButtonTableViewCellDelegate?

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let buttonItem = item as? ButtonTableViewCellItem {
			button?.setTitle(buttonItem.title, for: .normal)
			button?.pattern = buttonItem.buttonPattern
      if let color = buttonItem.buttonColor {
        button?.color = buttonItem.buttonColor
      }
			button?.isEnabled = buttonItem.isButtonEnabled
			activityIndicator?.isHidden = true

			buttonItem.isButtonEnabledObservable?
				.asDriver(onErrorJustReturn: true)
				.drive(button.rx.isEnabled)
				.disposed(by: disposeBag)

			buttonItem.isLoadingObserver?.bind(onNext: { [weak self] (val) in
				let defaultState = buttonItem.isButtonEnabled
				self?.button?.isEnabled = defaultState
				self?.activityIndicator?.isHidden = !val
				if val {
					self?.activityIndicator?.startAnimating()
					self?.button?.isEnabled = false
				} else {
					self?.activityIndicator?.stopAnimating()
				}
			}).disposed(by: disposeBag)

      buttonItem.buttonTitleObservable?.asDriver(onErrorJustReturn: nil)
        .drive(button.rx.title(for: .normal)).disposed(by: disposeBag)

			button?.rx.tap.asDriver(onErrorJustReturn: ())
				.drive(buttonItem.didTapButtonSubject).disposed(by: disposeBag)
		}
	}
  
  override func prepareForReuse() {
    super.prepareForReuse()

    self.button.setBackgroundImage(nil, for: .normal)
    self.button.setBackgroundImage(nil, for: .disabled)
  }

}
