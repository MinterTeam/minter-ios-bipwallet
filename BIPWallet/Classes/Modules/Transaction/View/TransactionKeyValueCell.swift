//
//  TransactionKeyValueCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class TransactionKeyValueCellItem: BaseCellItem {
  var key: String?
  var value: String?
}

class TransactionKeyValueCell: BaseCell {

  // MARK: - IBOutlet

  @IBOutlet weak var key: UILabel! {
    didSet {
      key.font = UIFont.semiBoldFont(of: 11.0)
    }
  }
  @IBOutlet weak var value: UILabel! {
    didSet {
      value.font = UIFont.semiBoldFont(of: 14.0)
    }
  }

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

    guard let item = item as? TransactionKeyValueCellItem else {
      return
    }
    key.text = item.key
    value.text = item.value
  }

}
