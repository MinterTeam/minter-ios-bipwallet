//
//  DefaultTextField.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class DefaultTextField: UITextField {

  override init(frame: CGRect) {
    super.init(frame: frame)

    customize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    customize()
  }

  func customize() {
//    self.textContainerInset = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 14.0, right: 16.0)
    self.font = UIFont.mediumFont(of: 17.0)
//    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 0.1
    self.layer.cornerRadius = 8.0
    self.backgroundColor = UIColor.textFieldBackgroundColor()
  }

  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: 16, y: 14, width: bounds.width - 16.0 - 16.0, height: bounds.height - 14.0 - 14.0)
  }

  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: 16, y: 14, width: bounds.width - 16.0 - 16.0, height: bounds.height - 14.0 - 14.0)
  }

  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: 16, y: 14, width: bounds.width - 16.0 - 16.0, height: bounds.height - 14.0 - 14.0)
  }

}
