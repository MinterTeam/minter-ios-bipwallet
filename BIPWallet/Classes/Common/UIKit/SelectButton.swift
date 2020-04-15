//
//  SelectButton.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 13.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

class SelectButton: UIButton {

  let disposeBag = DisposeBag()

  // MARK: -
  
  override var isSelected: Bool {
    didSet {
      setAppearance()
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    customize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    customize()
  }

  // MARK: -

  var isSelectedObservable = Observable.just(false)

  func customize() {
    self.layer.cornerRadius = 16.0
    self.layer.borderWidth = 1.0
    self.backgroundColor = .white
    self.layer.borderColor = UIColor(hex: 0xE5E5E5)?.cgColor
    self.tintColor = .clear
    self.titleEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    self.titleLabel?.font = UIFont.semiBoldFont(of: 14)

    self.setTitleColor(.mainBlackColor(), for: .normal)
    self.setTitleColor(.mainBlackColor(), for: .selected)

    self.setAppearance()

    self.rx.tap.subscribe(onNext: { (_) in
      self.isSelected = !self.isSelected
      self.setAppearance()
    }).disposed(by: disposeBag)
  }
  
  func setAppearance() {
    if self.isSelected {
      self.backgroundColor = UIColor.textFieldBackgroundColor()
      self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    } else {
      self.backgroundColor = .white
      self.layer.borderColor = UIColor(hex: 0xE5E5E5)?.cgColor
    }
  }
  
}
