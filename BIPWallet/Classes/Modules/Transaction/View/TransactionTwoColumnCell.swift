//
//  TransactionTwoColumnCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

class TransactionTwoColumnCellItem: BaseCellItem {
  var key1: String?
  var key2: String?

  var value1: String?
  var value1Interactable: Bool = false
  var value1DidTap = PublishSubject<Void>()

  var value2: String?
  var value2Interactable: Bool = false
  var value2DidTap = PublishSubject<Void>()
}

class TransactionTwoColumnCell: BaseCell {

  // MARK: - IBOutlet

  @IBOutlet weak var key1: UILabel!
  @IBOutlet weak var key2: UILabel!
  @IBOutlet weak var value1: UIButton! {
    didSet {
      value1.titleLabel?.font = UIFont.semiBoldFont(of: 14.0)
    }
  }
  @IBOutlet weak var value2: UIButton! {
    didSet {
      value2.titleLabel?.font = UIFont.semiBoldFont(of: 14.0)
    }
  }
  @IBOutlet weak var value1Label: UILabel!
  @IBOutlet weak var value2Label: UILabel!

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
    value1Label.text = item.value1

    value2.setTitle(item.value2, for: .normal)
    value2Label.text = item.value2

    value1.isEnabled = item.value1Interactable
    if item.value1Interactable {
      value1.setTitleColor(.mainPurpleColor(), for: .normal)
    }

    value2.isEnabled = item.value2Interactable
    if item.value2Interactable {
      value2.setTitleColor(.mainPurpleColor(), for: .normal)
    }

    value1.rx.tap.asDriver().drive(item.value1DidTap).disposed(by: disposeBag)
    value2.rx.tap.asDriver().drive(item.value2DidTap).disposed(by: disposeBag)
  }

}
