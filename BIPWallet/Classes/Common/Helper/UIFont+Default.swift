//
//  UIFont+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

let defaultFontNameRegular = "Inter"
let defaultFontNameMedium = "Inter_Medium"
let defaultFontNameBold = "Inter_Bold"
let defaultFontNameSemiBold = "Inter_Semi-Bold"

extension UIFont {

	static func defaultFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameRegular, size: size)!.slashedZeroes()
	}

  static func semiBoldFont(of size: CGFloat) -> UIFont {
    return UIFont(name: defaultFontNameSemiBold, size: size)!.slashedZeroes()
  }

	static func boldFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameBold, size: size)!.slashedZeroes()
	}

	static func mediumFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameMedium, size: size)!.slashedZeroes()
	}

  func slashedZeroes() -> UIFont {
    let originalFontDescriptor = self.fontDescriptor

    let fontDescriptorFeatureSettings = [
      [UIFontDescriptor.FeatureKey.featureIdentifier: 14,
        UIFontDescriptor.FeatureKey.typeIdentifier: 4],
    ]

    let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
    let fontDescriptor = originalFontDescriptor.addingAttributes(fontDescriptorAttributes)
    let font = UIFont(descriptor: fontDescriptor, size: 0)

    return font
  }

}
