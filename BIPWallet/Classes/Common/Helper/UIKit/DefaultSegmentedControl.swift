//
//  DefaultSegmentedControl.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 08.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

class DefaultSegmentedControl: UISegmentedControl {
  
  override var selectedSegmentIndex: Int {
    didSet {
      guard #available(iOS 13.0, *) else {
        setSegmentColor()
        return
      }
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    self.setFont(UIFont.semiBoldFont(of: 14.0))

    guard #available(iOS 13.0, *) else {
      belowIos13Appearance()
      return
    }
  }

  func belowIos13Appearance() {
    self.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
    setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    self.backgroundColor = UIColor(hex: 0x767680, alpha: 0.24)
    self.layer.cornerRadius = 16.0
    self.addTarget(self, action: #selector(setSegmentColor), for: .allEvents)
    self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.mainBlackColor()], for: .selected)
    self.tintColor = UIColor(hex: 0x767680, alpha: 0.24)
    setSegmentColor()
  }

  @objc
  func setSegmentColor() {
    let sortedViews = self.subviews.sorted( by: { $0.frame.origin.x < $1.frame.origin.x } )

    for (index, view) in sortedViews.enumerated() {
      if index == self.selectedSegmentIndex {
        view.backgroundColor = .white
        view.layer.cornerRadius = 16.0
        view.layer.borderColor = UIColor(hex: 0x767680, alpha: 0.24)?.cgColor
        view.layer.borderWidth = 2
      } else {
        view.backgroundColor = .clear
        view.layer.borderWidth = 0
        view.layer.borderColor = UIColor(hex: 0x767680, alpha: 0.24)?.cgColor
        view.subviews.forEach { (subview) in
          (subview as? UILabel)?.textColor = UIColor(hex: 0x8E8E8E)
        }
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    guard #available(iOS 13.0, *) else {
      setSegmentColor()
      return
    }
  }

}
