//
//  PopupLoadingView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import SnapKit

@IBDesignable
class PopupLoadingView: UIView {

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    initializeView()

    startAnimating()
  }

  let activityIndicator = UIActivityIndicatorView()
  let label = UILabel()

  func initializeView() {
    self.addSubview(activityIndicator)
    self.addSubview(label)

    label.text = "Please wait a few seconds…".localized()
    label.font = .mediumFont(of: 17.0)
    label.numberOfLines = 0
    label.textColor = .mainBlackColor()
    activityIndicator.style = .gray

    activityIndicator.snp.makeConstraints { (maker) in
      maker.leading.equalTo(self).offset(37)
      maker.width.height.equalTo(20)
      maker.centerY.equalTo(label)
    }

    label.snp.makeConstraints { (maker) in
      maker.leading.equalTo(activityIndicator.snp.trailing).offset(26)
      maker.trailing.equalTo(self.snp.trailing)
      maker.top.equalTo(self).offset(20)
      maker.bottom.equalTo(self).offset(-20)
    }
  }

  func startAnimating() {
    self.activityIndicator.startAnimating()
    self.activityIndicator.isHidden = false
  }

  func stopAnimating() {
    self.activityIndicator.stopAnimating()
    self.activityIndicator.isHidden = true
  }

}
