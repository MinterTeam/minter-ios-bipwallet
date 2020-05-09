//
//  LocalStorageAppSettings.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

class LocalStorageAppSettings: AppSettings {

  @LocalStorage("userId", defaultValue: true)
  var isSoundEnabled: Bool

  @LocalStorage("balanceType", defaultValue: "balanceBIP")
  var balanceType: String
}
