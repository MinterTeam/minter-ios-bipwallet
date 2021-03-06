//
//  DelegatedCoinTableViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26.08.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import AlamofireImage
import MinterCore
import RxSwift

class DelegatedCoinTableViewCellItem: BaseCellItem {
  var title: String?
  var image: UIImage?
  var imageURL: URL?
  var date: Date?
  var coin: String?
  var amount: Decimal?
  var bipAmount: Decimal?
  var amountObservable: Observable<Decimal?>?

  var didTapMinus = PublishSubject<Void>()
}

class DelegatedCoinTableViewCell: BaseCell {

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
  @IBOutlet weak var minusButton: UIButton!
  @IBOutlet weak var coinImageWrapper: UIView! {
    didSet {
      coinImageWrapper.backgroundColor = .clear
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

    guard let transaction = item as? DelegatedCoinTableViewCellItem else {
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

    minusButton.rx.tap.subscribe(transaction.didTapMinus).disposed(by: disposeBag)
  }

  // MARK: -

  override func prepareForReuse() {
    super.prepareForReuse()
    self.title.text = ""
    self.amount.text = ""
    self.coin.text = ""
    self.coinImage.image = nil
  }

}
