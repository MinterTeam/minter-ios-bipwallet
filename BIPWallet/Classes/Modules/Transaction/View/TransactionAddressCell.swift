//
//  TransactionAddressCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import AlamofireImage

class TransactionAddressCellItem: BaseCellItem {
  var avatarURL: URL?
  var avatar: UIImage?
  var title: String?
  var name: String?
  var address: String?
}

class TransactionAddressCell: BaseCell {

  // MARK: - IBOutput

  @IBOutlet weak var avatar: UIImageView!
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var address: UIButton!
  @IBOutlet weak var addressLabel: UILabel!

  // MARK: -

  override func awakeFromNib() {
    super.awakeFromNib()

    avatar.makeBorderWithCornerRadius(radius: 16.0,
                                      borderColor: UIColor.clear,
                                      borderWidth: 1.0)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  // MARK: -

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? TransactionAddressCellItem else {
      return
    }

    if let avatarImage = item.avatar {
      avatar.image = avatarImage
    } else if let url = item.avatarURL {
      avatar.af_setImage(withURL: url)
    }
    title.text = item.title
    name.text = item.name
    address.setTitle(item.address, for: .normal)
    addressLabel.text = item.address
  }

}
