//
//  DefaultHeader.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SendHeader: UITableViewHeaderFooterView {

  var disposeBag = DisposeBag()
  var timerText: Observable<NSAttributedString?>?

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var timerButton: UIButton!

  func configure(timerText: Observable<NSAttributedString?>) {
    timerText.asDriver(onErrorJustReturn: nil)
      .drive(self.timerButton.rx.attributedTitle(for: .normal))
      .disposed(by: disposeBag)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

}
