//
//  UIColor+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 08/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

extension UIColor {

  static func mainWhiteColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(white: 1.0, alpha: alpha)
  }

	static func mainColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x502EC2, alpha: alpha)!
	}

	static func mainGreenColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x35B65C, alpha: alpha)!
	}

	static func mainRedColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0xEC373C, alpha: alpha)!
	}

	static func mainGreyColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x929292, alpha: alpha)!
	}

  static func secondaryGreyColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0x8E8E8E, alpha: alpha)!
  }

  static func mainPurpleColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0x502EC2, alpha: alpha)!
  }

  static func mainBlackColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0x191919, alpha: alpha)!
  }

  static func textFieldBorderColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0xE0DAF4, alpha: alpha)!
  }

  static func textFieldBackgroundColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0xF4F4F4, alpha: alpha)!
  }
  
  static func activeTextFieldBackgroundColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0xF7F5FF, alpha: alpha)!
  }

  static func textFieldPlaceholderTextColor(alpha: CGFloat = 1) -> UIColor {
    return UIColor(hex: 0x8E8E8E, alpha: alpha)!
  }

  static func tableViewCellActionRedColor(alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(hex: 0xDC4840, alpha: alpha)!
  }

}
