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
  case hasAccount
}

protocol AuthStateProvider {
  var authState: AuthState { get }
}

protocol AuthService {
  func addAccount(_ account: Account)
  func logout()
}

final class AuthServiceImpl: AuthService, AuthStateProvider {

  var storage: AuthStorage!

  // MARK: - AuthService

  func addAccount(_ account: Account) {
    storage.save(address: account.address, mnemonic: "") { (success) in
      
    }
  }

  func logout() {
    storage.deleteAllAccounts()
  }

  // MARK: - AuthStateProvider

  var authState: AuthState {
    return storage.hasAccounts() ? AuthState.hasAccount : .noAccount
  }
}
