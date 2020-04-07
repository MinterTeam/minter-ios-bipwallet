//
//  AuthService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterMy

enum AuthState {
  case noAccount
  case pinNeeded
  case hasAccount
}

protocol AuthStateProvider {
  var authState: AuthState { get }
}

protocol AuthService {
  func accounts() -> [AccountItem]
  func hasAccount() -> Bool
  func addAccount(mnemonic: String)
  func logout()
}
