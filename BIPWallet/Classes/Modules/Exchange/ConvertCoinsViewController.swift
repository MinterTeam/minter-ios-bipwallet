//
//  ConvertCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import NotificationBannerSwift

class ConvertCoinsViewController: BaseViewController {

	// MARK: -

	let coinFormatter = CurrencyNumberFormatter.coinFormatter

	// MARK: -

	@IBOutlet weak var feeLabel: UILabel! {
		didSet {
			feeLabel.layer.zPosition = -1
		}
	}
  @IBOutlet weak var approximately: UILabel! {
    didSet {
      approximately.font = UIFont.semiBoldFont(of: 18.0)
    }
  }
	@IBOutlet weak var getActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var exchangeButton: DefaultButton!
	@IBOutlet weak var autocompleteViewWrapper: UIView!
	@IBOutlet weak var autocompleteView: LUAutocompleteView! {
		didSet {
			autocompleteView.autocompleteCellNibName = "CoinAutocompleteCell"
		}
	}
	@IBOutlet weak var getCoinTextField: UITextField!
  @IBOutlet weak var spendCoinTextField: UITextField!
  @IBOutlet weak var multipleWalletsImage: UIImageView!
  @IBOutlet weak var loadingView: PopupLoadingView!

	// MARK: -

	var viewModel: ConvertCoinsViewModel!

	override func viewDidLoad() {
		super.viewDidLoad()

    viewModel.hasMultipleCoinsObserver.asDriver(onErrorJustReturn: false)
      .map {!$0}.drive(multipleWalletsImage.rx.isHidden)
      .disposed(by: disposeBag)

    viewModel.endEditing.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] in
      self?.view.endEditing(true)
      }).disposed(by: disposeBag)

		viewModel.feeObservable
			.asDriver(onErrorJustReturn: "")
			.drive(feeLabel.rx.text)
			.disposed(by: self.disposeBag)

		autocompleteView.textField = getCoinTextField
    getCoinTextField.rx.text
      .map { $0?.uppercased() }
      .subscribe(getCoinTextField.rx.text)
      .disposed(by: disposeBag)

    viewModel.isApproximatelyLoading
      .distinctUntilChanged()
      .debounce(.milliseconds(10), scheduler: MainScheduler.instance)
      .subscribe(onNext: { val in
        var delay = 0.0
        if val {
          self.loadingView.startAnimating()
        } else {
          delay = 1.0
        }
        UIView.animate(withDuration: 0.5, delay: delay, options: [.allowUserInteraction], animations: {
          self.loadingView.alpha = val ? 1.0 : 0.0
        }) { (comop) in
        }
      }).disposed(by: disposeBag)

		autocompleteView.dataSource = viewModel
		autocompleteView.delegate = viewModel
	}

	// MARK: -

  func showPicker() {
    let items = SpendCoinPickerItem.items(with: viewModel.spendCoinPickerSource)

    guard items.count > 0 else {
      return
    }

    let data: [[String]] = [items.map({ (item) -> String in
      return item.title ?? ""
    })]

    let picker = McPicker(data: data)
    picker.toolbarButtonsColor = .white
    picker.toolbarDoneButtonColor = .white
    picker.toolbarBarTintColor = UIColor(hex: 0x4225A4)
    picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
    picker.show { [weak self] (selected) in
      self?.spendCoinTextField.text = selected.first?.value
      self?.spendCoinTextField.sendActions(for: .valueChanged)
    }
  }

}

extension ConvertCoinsViewController: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if textField == spendCoinTextField {
      self.showPicker()
      self.view.endEditing(true)
      return false
    }
    return true
  }

}
