//
//  AppSettings.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol AppSettings {
  var isSoundEnabled: Bool { get set }
  var balanceType: String { get set }
  var showStories: Bool { get set }
  var showStoriesObservable: Observable<Bool?> { get }
}
