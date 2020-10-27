//
//  LocalStorageAppSettings.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class LocalStorageAppSettings: AppSettings {

  @LocalStorage("isSoundEnabled", defaultValue: true)
  var isSoundEnabled: Bool

  @LocalStorage("balanceType", defaultValue: "balanceBIP")
  var balanceType: String

  @LocalStorage("showStories", defaultValue: true)
  var showStories: Bool

  var showStoriesObservable: Observable<Bool?> {
    return UserDefaults.standard.rx.observe(Bool.self, "showStories")
  }

}
