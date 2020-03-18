//
//  TransactionTwoColumnCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class TransactionTwoColumnCellItem: BaseCellItem {
  var key1: String?
  var key2: String?

  var value1: String?
  var value1Interactable: Bool = false

  var value2: String?
  var value2Interactable: Bool = false
}

class TransactionTwoColumnCell: BaseCell {

  // MARK: - IBOutlet

  @IBOutlet weak var key1: UILabel!
  @IBOutlet weak var key2: UILabel!
  @IBOutlet weak var value1: UIButton!
  @IBOutlet weak var value2: UIButton!

  // MARK: -

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  // MARK: - Configurable

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? TransactionTwoColumnCellItem else {
      return
    }

    key1.text = item.key1
    key2.text = item.key2

    value1.setTitle(item.value1, for: .normal)
    value2.setTitle(item.value2, for: .normal)

    value1.isEnabled = item.value1Interactable
    value2.isEnabled = item.value2Interactable
    
  }

}
