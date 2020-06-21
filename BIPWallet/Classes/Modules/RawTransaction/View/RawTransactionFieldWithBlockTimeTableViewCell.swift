//
//  RawTransactionFieldWithBlockTimeTableViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21.06.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RawTransactionFieldWithBlockTimeTableViewCellItem: RawTransactionFieldTableViewCellItem {
  var lastBlockText: Observable<NSAttributedString>?
}

class RawTransactionFieldWithBlockTimeTableViewCell: RawTransactionFieldTableViewCell {

  @IBOutlet weak var lastBlockButton: UIButton!

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? RawTransactionFieldWithBlockTimeTableViewCellItem else {
      return
    }

    item.lastBlockText?.asDriver(onErrorJustReturn: NSAttributedString()).drive(lastBlockButton.rx.attributedTitle(for: .normal)).disposed(by: disposeBag)
  }

}
