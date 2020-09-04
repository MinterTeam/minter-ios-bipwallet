//
//  RawTransactionConvertCoinCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 09.08.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RawTransactionConvertCoinCellItem: BaseCellItem {
  var title: Observable<String?>?

  var exchange = PublishSubject<Void>()

}

class RawTransactionConvertCoinCell: BaseCell {

  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var actionButton: UIButton!

  // MARK: -

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  // MARK: - Configure

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? RawTransactionConvertCoinCellItem else { return }

    item.title?.asDriver(onErrorJustReturn: nil).drive(label.rx.text).disposed(by: disposeBag)

    actionButton.rx.tap.asDriver().drive(item.exchange).disposed(by: disposeBag)

  }

}
