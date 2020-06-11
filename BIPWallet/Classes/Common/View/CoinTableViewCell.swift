//
//  TransactionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage
import MinterCore
import RxSwift

class CoinTableViewCellItem: BaseCellItem {
	var title: String?
	var image: UIImage?
	var imageURL: URL?
	var date: Date?
	var coin: String?
	var amount: Decimal?
  var bipAmount: Decimal?
	var amountObservable: Observable<Decimal?>?
}

class CoinTableViewCell: BaseCell {

	// MARK: -

	private let formatter = CurrencyNumberFormatter.coinFormatter

	// MARK: - IBOutlet

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var coinImage: UIImageView! {
		didSet {
			coinImage.makeBorderWithCornerRadius(radius: 16,
																					 borderColor: .clear,
																					 borderWidth: 0)
		}
	}
  @IBOutlet weak var amount: UILabel! {
    didSet {
      amount.font = UIFont.semiBoldFont(of: 14.0)
    }
  }
	@IBOutlet weak var coin: UILabel!
	@IBOutlet weak var amountLeadingConstraint: NSLayoutConstraint! {
		didSet {
			amountLeadingConstraints = amountLeadingConstraint
		}
	}
	var amountLeadingConstraints: NSLayoutConstraint?
	@IBOutlet weak var amountBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var coinImageWrapper: UIView! {
		didSet {
			coinImageWrapper.backgroundColor = .clear
		}
	}

	private var isShowingCoin = false

	@IBAction func didTapCell(_ sender: Any) {

		if self.title.frame.width > self.amount.frame.width {
			return
		}

		if !isShowingCoin {
			self.amountLeadingConstraint?.isActive = false
			self.amountLeadingConstraints?.isActive = false
			amount.adjustsFontSizeToFitWidth = true

			UIView.animate(withDuration: 0.2, animations: { [weak self] in
				self?.title.alpha = 0.0
				self?.layoutIfNeeded()
			}) { [weak self] (finished) in
				self?.isShowingCoin = true
			}
		} else {
      amount.adjustsFontSizeToFitWidth = false
      self.amountLeadingConstraint?.isActive = true
      UIView.animate(withDuration: 0.2, animations: { [weak self] in
        self?.title.alpha = 1.0
        self?.layoutIfNeeded()
      }) { [weak self] (finished) in
        self?.isShowingCoin = false
      }
		}
	}

	// MARK: -

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
    super.configure(item: item)

		guard let transaction = item as? CoinTableViewCellItem else {
      return
    }

    title.text = transaction.title
    coinImage.image = transaction.image
    if let url = transaction.imageURL {
      coinImage.af_setImage(withURL: url,
                            filter: RoundedCornersFilter(radius: 16.0))
    } else {
      coinImage.image = transaction.image
    }

    amount.text = CurrencyNumberFormatter.formattedDecimal(with: transaction.amount ?? 0,
                                                           formatter: formatter)

    if let bipAmount = transaction.bipAmount {
      let amnt = CurrencyNumberFormatter.formattedDecimal(with: bipAmount,
                                                          formatter: formatter)
      coin.text = amnt + " " + (Coin.baseCoin().symbol ?? "")
    }

    transaction.amountObservable?.subscribe(onNext: { [weak self] (val) in
      self?.amount.text = CurrencyNumberFormatter.formattedDecimal(with: val ?? 0,
                                                                   formatter: self!.formatter)
    }).disposed(by: disposeBag)
		
	}

	// MARK: -

	override func layoutSubviews() {
		super.layoutSubviews()
	}

  override func prepareForReuse() {
    super.prepareForReuse()
    self.title.text = ""
    self.amount.text = ""
    self.coin.text = ""
    self.coinImage.image = nil
  }

}
