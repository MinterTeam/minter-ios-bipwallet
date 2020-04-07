//
//  ContactEntryTableViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import AlamofireImage

class ContactEntryTableViewCellItem: BaseCellItem {
  var address: String?
  var name: String?
  var avatarURL: URL?
}

class ContactEntryTableViewCell: BaseCell {

  // MARK: - IBOutput

  @IBOutlet weak var avatarImage: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!

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

    guard let item = item as? ContactEntryTableViewCellItem else {
      return
    }

    if let imageURL = item.avatarURL {
      avatarImage.af_setImage(withURL: imageURL)
    }
    nameLabel.text = item.name
    addressLabel.text = item.address
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    nameLabel.text = nil
    addressLabel.text = nil
    avatarImage.image = UIImage(named: "AvatarPlaceholderImage")
  }

}
