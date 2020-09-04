//
//  ValidatorTableViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26.08.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//


import UIKit
import AlamofireImage

class ValidatorTableViewCellItem: BaseCellItem {
  var publicKey: String?
  var name: String?
  var avatarURL: URL?
  var commission: String?
  var minStake: String?
}

class ValidatorTableViewCell: BaseCell {

  // MARK: - IBOutput

  @IBOutlet weak var avatarImage: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var commissionLabel: UILabel!
  @IBOutlet weak var minStakeLabel: UILabel!

  // MARK: -

  override func awakeFromNib() {
    super.awakeFromNib()

    avatarImage.image = UIImage(named: "AvatarPlaceholderImage")
    avatarImage.makeBorderWithCornerRadius(radius: 16.0,
                                           borderColor: UIColor.clear,
                                           borderWidth: 1.0)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  // MARK: -

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? ValidatorTableViewCellItem else {
      return
    }

    if let imageURL = item.avatarURL {
      avatarImage.af_setImage(withURL: imageURL)
    }
    nameLabel.text = item.name
    addressLabel.text = item.publicKey
    commissionLabel.text = item.commission
    minStakeLabel.text = item.minStake
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    nameLabel.text = nil
    addressLabel.text = nil
    avatarImage.image = UIImage(named: "AvatarPlaceholderImage")
  }

}
