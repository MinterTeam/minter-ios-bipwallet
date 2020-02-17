//
//  AuthStorage.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterMy

protocol AuthStorage: class {

  func hasAccounts() -> Bool
//  func save(address: String, mnemonic: String, completion: ((Bool) -> ())?)
  func deleteAllAccounts()

}
