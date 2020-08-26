//
//  RawTransactionTextViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.08.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

class RawTransactionTextViewCellItem: TextViewTableViewCellItem {
  var lastBlockText: Observable<NSAttributedString>?
  var state = PublishSubject<TextViewTableViewCell.State?>()
}

class RawTransactionTextViewCell: TextViewTableViewCell {

  @IBOutlet weak var lastBlockButton: UIButton!

  // MARK: -

  var maxLength = 110

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    textView?.superview?.layer.cornerRadius = 8.0
    setDefault()
    activityIndicator?.backgroundColor = .clear
    textView.font = UIFont.mediumFont(of: 17.0)
    textView.autocorrectionType = .no
  }

  @objc override func setValid() {
    self.errorTitle.text = ""
  }

  @objc override func setInvalid(message: String?) {
    if nil != message {
      self.errorTitle?.text = message
    }
  }

  @objc override func setDefault() {
    self.errorTitle?.text = ""
  }

  // MARK: -

  override func configure(item: BaseCellItem) {
    super.configure(item: item)

    guard let item = item as? RawTransactionTextViewCellItem else {
      return
    }

    textView.text = item.value

    item.lastBlockText?
      .asDriver(onErrorJustReturn: NSAttributedString())
      .drive(lastBlockButton.rx.attributedTitle(for: .normal))
      .disposed(by: disposeBag)

    item.lastBlockText?.map { !($0.string.count > 0) }
      .subscribe(lastBlockButton.rx.isHidden)
      .disposed(by: disposeBag)

    item.state.subscribe(onNext: { (state) in
      switch state {
      case .invalid(let error):
        self.setInvalid(message: error)
      case .default:
        self.setDefault()
      case .valid:
        self.setValid()
      case .none:
        self.setDefault()
      }
    }).disposed(by: disposeBag)

  }

}
