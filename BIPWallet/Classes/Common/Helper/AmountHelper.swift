//
//  AmountHelper.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxBiBinding

class AmountHelper {

  class func transformValue(value: String?) -> String? {
    var newValue = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
    if newValue?.starts(with: ".") ?? false {
      newValue = "0." + (newValue?.trimmingCharacters(in: CharacterSet(charactersIn: ".")) ?? "")
    }
    return newValue
  }
}
