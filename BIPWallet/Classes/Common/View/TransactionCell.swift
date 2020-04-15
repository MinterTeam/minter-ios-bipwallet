//
//  TransactionCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 24.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import AlamofireImage

class TransactionCellItem: BaseCellItem {
  var txHash: String?
  var imageURL: URL?
  var image: UIImage?
  var type: String?
  var title: String?
  var amount: String?
  var coin: String?
}

class TransactionCell: BaseCell {

  // MARK: -

  @IBOutlet weak var transactionImage: UIImageView! {
    didSet {
      transactionImage.layer.cornerRadius = 8.0
      transactionImage.makeBorderWithCornerRadius(radius: 8.0,
                                           borderColor: .clear,
                                           borderWidth: 0.0)
    }
  }
  @IBOutlet weak var type: UILabel!
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var amount: UILabel!
  @IBOutlet weak var coin: UILabel!

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

    guard let item = item as? TransactionCellItem else { return }

    title.text = TransactionTitleHelper.title(from: item.title ?? "")
    transactionImage.image = UIImage(named: "AvatarPlaceholderImage")
    if let url = item.imageURL {
      transactionImage.af_setImage(withURL: url,
                            filter: RoundedCornersFilter(radius: 16.0))
    } else if let image = item.image {
      transactionImage.image = image
    }
    amount.text = item.amount
    coin.text = item.coin
    type.text = item.type
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    transactionImage.image = nil
    title.text = nil
    type.text = nil
    amount.text = nil
    coin.text = nil
  }

}
