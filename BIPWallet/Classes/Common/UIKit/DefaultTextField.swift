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
    addObservers()

    self.font = UIFont.mediumFont(of: 17.0)
    self.layer.borderWidth = 0
    self.layer.cornerRadius = 8.0
    self.backgroundColor = UIColor.textFieldBackgroundColor()
  }

  func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(didStartEditing(notification:)), name: UITextField.textDidBeginEditingNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didEndEditing(notification:)), name: UITextField.textDidEndEditingNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func didStartEditing(notification: NSNotification) {
    guard (notification.object as AnyObject?) === self else { return }
    self.backgroundColor = UIColor.activeTextFieldBackgroundColor()
    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 1
  }

  @objc func didEndEditing(notification: NSNotification) {
    guard (notification.object as AnyObject?) === self else { return }
    self.backgroundColor = UIColor.textFieldBackgroundColor()
    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 0
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
