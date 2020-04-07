//
//  ContactItem.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 30.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

struct ContactItem: Comparable {

  var name: String?
  var address: String?

  static func < (lhs: ContactItem, rhs: ContactItem) -> Bool {
    return (lhs.name ?? "") < (rhs.name ?? "")
  }

}
