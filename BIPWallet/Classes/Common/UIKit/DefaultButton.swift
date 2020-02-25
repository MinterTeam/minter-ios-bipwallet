//
//  DefaultButton.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

@IBDesignable
class DefaultButton: UIButton {

	@IBInspectable
	dynamic open var animateButtonTouch: Bool = true {
		didSet {
			if animateButtonTouch {
				self.addTarget(self, action: #selector(DefaultButton.animateButtonTouchDidTouchDown(_:)),
                       for: UIControl.Event.touchDown)
			} else {
				self.removeTarget(self, action: #selector(DefaultButton.animateButtonTouchDidTouchDown(_:)),
                          for: UIControl.Event.touchDown)
			}
		}
	}

	// MARK: -

	@IBInspectable var pattern: String? {
		didSet {
			self.updateAppearance()
		}
	}

	func updateAppearance() {

		if pattern == "blank" {
			self.backgroundColor = .clear
			self.layer.borderWidth = 2.0
      self.layer.borderColor = UIColor.mainPurpleColor().cgColor
			self.setTitleColor(UIColor.mainPurpleColor(), for: .normal)
		} else if pattern == "transparent" {
			self.backgroundColor = .clear
			self.layer.borderWidth = 2.0
			self.layer.borderColor = UIColor.white.cgColor
			self.setTitleColor(.white, for: .normal)
		} else if pattern == "filled" {
      self.backgroundColor = .mainWhiteColor()
      self.layer.borderColor = UIColor.mainWhiteColor().cgColor
			self.setTitleColor(.black, for: .normal)
			self.layer.borderWidth = 0.0
			addShadow()
    } else if pattern == "purple" {
      self.setBackgroundImage(UIImage(named: "DefaultButtonActive"), for: .normal)
      self.setBackgroundImage(UIImage(named: "DefaultButtonDisabled"), for: .disabled)
      self.setTitleColor(.white, for: .normal)
      self.setTitleColor(UIColor(hex: 0x8E8E8E), for: .disabled)

//      addShadow()
    } else {
			self.layer.borderWidth = 0.0
			self.backgroundColor = .white
			self.setTitleColor(UIColor.mainColor(), for: .normal)
			addShadow()
		}

//		if state == .disabled {
//			clearShadow()
//		}
	}

	func addShadow() {
    self.layer.shadowColor = UIColor.mainColor(alpha: 0.3).cgColor
		self.layer.shadowPath = UIBezierPath(roundedRect: bounds,
																				 cornerRadius: layer.cornerRadius).cgPath
		self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
		self.layer.shadowRadius = 2.0
		self.layer.masksToBounds = false
		self.layer.shadowOpacity = 1.0
	}

	func clearShadow() {
		self.layer.shadowColor = UIColor.clear.cgColor
		self.layer.shadowPath = UIBezierPath(rect: CGRect.zero).cgPath
	}

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()

		self.titleLabel?.font = UIFont.semiBoldFont(of: 18.0)
		self.layer.cornerRadius = 16.0
		self.updateAppearance()
		self.animateButtonTouch = true
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		updateAppearance()
	}

	// MARK: -

	@objc func animateButtonTouchDidTouchDown(_ sender: UIButton) {

		UIView.animate(withDuration: 0.1,
									 delay: 0.0,
									 usingSpringWithDamping: 10,
									 initialSpringVelocity: 1,
									 options: [.allowUserInteraction],
									 animations: { [weak self]() -> Void in
										self?.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
		}) { (result) -> Void in
			UIView.animate(withDuration: 0.1,
										 animations: { [weak self] () -> Void in
											self?.transform = CGAffineTransform(scaleX: 1, y: 1)
			})
		}
	}

}
