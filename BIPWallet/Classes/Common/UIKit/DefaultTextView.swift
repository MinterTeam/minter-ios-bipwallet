//
//  DefaultTextView.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class DefaultTextView: UITextView {

  private var placeholderLabel: UILabel!

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    customize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    customize()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func customize() {
    self.textContainerInset = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 14.0, right: 16.0)
    self.font = UIFont.mediumFont(of: 17.0)
    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 1
    self.layer.cornerRadius = 8.0
    self.backgroundColor = UIColor.textFieldBackgroundColor()
    setupUI()
    startupSetup()
  }

}

// MARK: - Setup UI

private extension DefaultTextView {
  func setupUI() {
    addPlaceholderLabel()

    textColor = .black
  }

  func addPlaceholderLabel() {
    placeholderLabel = UILabel(frame: .zero)
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(placeholderLabel, at: 0)

    placeholderLabel.alpha = 0
    placeholderLabel.numberOfLines = 0
    placeholderLabel.backgroundColor = .clear
    placeholderLabel.textColor = UIColor.textFieldPlaceholderTextColor()
    placeholderLabel.lineBreakMode = .byWordWrapping
    placeholderLabel.isUserInteractionEnabled = false
    placeholderLabel.font = UIFont.mediumFont(of: 17)

    placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: self.textContainerInset.top).isActive = true
    placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: self.textContainerInset.left).isActive = true
    placeholderLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: self.textContainerInset.right).isActive = true
    placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: self.textContainerInset.bottom).isActive = true
  }
}

// MARK: - Startup
private extension DefaultTextView {
  func startupSetup() {
    addObservers()
    textChanged(nil)
    font = UIFont.mediumFont(of: 17)
  }

  func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: UITextView.textDidChangeNotification, object: nil)
  }
}

// MARK: - Actions

private extension DefaultTextView {
  @objc func textChanged(_ sender: Notification?) {
    UIView.animate(withDuration: 0.2) {
      self.placeholderLabel.alpha = self.text.count == 0 ? 1 : 0
    }
  }
}

// MARK: - Public methods

extension DefaultTextView {
  public func setPlaceholder(_ placeholder: String) {
    placeholderLabel.text = placeholder
  }
}
