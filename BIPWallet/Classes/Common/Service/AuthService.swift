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
  func logout()
}

final class LocalStorageAuthService: AuthService, AuthStateProvider {

  var storage: AuthStorage

  init(storage: AuthStorage) {
    self.storage = storage
  }

  // MARK: - AuthService

  func logout() {
    storage.deleteAllAccounts()
  }

  // MARK: - AuthStateProvider

  var authState: AuthState {
    return storage.hasAccounts() ? .hasAccount : .noAccount
  }
}
