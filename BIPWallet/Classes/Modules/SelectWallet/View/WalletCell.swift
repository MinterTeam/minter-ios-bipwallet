//
//  WalletCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

class WalletCellItem: BaseCellItem {
  var emoji: String?
  var title: String?

  var didTapEdit = PublishSubject<Void>()
}

class WalletCell: BaseCell {

  // MARK: -

  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var emoji: UILabel!

  // MARK: -

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? WalletCellItem else { return }

    emoji.text = item.emoji
    title.text = item.title
  }

}
