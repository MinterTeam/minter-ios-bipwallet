//
//  HandlerView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import SnapKit

class HandlerView: UIView {

  private let handlerImage = UIImage(named: "HandlerImage")!

  // MARK: -

  let titleLabel = UILabel()

  var title: String? = "" {
    didSet {
      titleLabel.text = title
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    let imageView = UIImageView(image: handlerImage)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(imageView)

    
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = self.title
    titleLabel.font = UIFont.boldFont(of: 18.0)
    self.addSubview(titleLabel)

    imageView.snp.makeConstraints { (maker) in
      maker.centerX.equalTo(self)
      maker.top.equalTo(8)
      maker.height.equalTo(5)
      maker.width.equalTo(71)
    }

    titleLabel.snp.makeConstraints { (maker) in
      maker.centerX.equalTo(self)
      maker.top.equalTo(imageView).offset(17)
      maker.height.equalTo(21)
    }

    self.layer.cornerRadius = 13.0
    self.layer.masksToBounds = true
  }

}
