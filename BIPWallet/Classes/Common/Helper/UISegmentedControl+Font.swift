//
//  UISegmentedControl+Font.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 23.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import UIKit

extension UISegmentedControl {

  func setFont(_ font: UIFont) {
    let attributedSegmentFont = NSDictionary(object: font, forKey: NSAttributedString.Key.font as NSCopying) as? [NSAttributedString.Key: Any]
    setTitleTextAttributes(attributedSegmentFont, for: .normal)
  }

}
