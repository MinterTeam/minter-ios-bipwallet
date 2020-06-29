//
//  LastBlockViewable.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16.06.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

protocol LastBlockViewable {
  func headerViewLastUpdatedTitleText(seconds: TimeInterval, shortened: Bool) -> NSAttributedString
}

extension LastBlockViewable {

  func headerViewLastUpdatedTitleText(seconds: TimeInterval, shortened: Bool = false) -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Last updated ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 12.0)]))
    var dateText = "\(Int(seconds)) "
    dateText += shortened ? "sec" : "seconds"
    if seconds < 5 {
      dateText = "just now".localized()
    } else if seconds > 60 * 60 {
      dateText = "more than ".localized()
      dateText += shortened ? "hour" : "an hour"
    } else if seconds > 60 {
      dateText = "more than ".localized()
      dateText += shortened ? "min" : "a minute"
    }
    string.append(NSAttributedString(string: dateText,
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 12.0)]))
    if seconds >= 5 {
      string.append(NSAttributedString(string: " ago".localized(),
                                       attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                    .font: UIFont.defaultFont(of: 12.0)]))
    }
    return string
  }
  
}
