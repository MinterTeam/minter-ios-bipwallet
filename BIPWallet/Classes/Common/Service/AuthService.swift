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
  func accounts() -> [Account]
  func hasAccount() -> Bool
  func addAccount(mnemonic: String)
  func logout()
}

final class LocalStorageAuthService: AuthService, AuthStateProvider {

  // Storage to store PKs
  private let storage: Storage
  // Manager to manage DB records
  private let accountManager: AccountManager
  private let databaseStorage = RealmDatabaseStorage.shared

  init(storage: Storage, accountManager: AccountManager) {
    self.storage = storage
    self.accountManager = accountManager
  }

  // MARK: - AuthService
  
  func accounts() -> [Account] {
    guard let accounts = accountManager.loadLocalAccounts(), accounts.count > 0 else {
      return []
    }

    let newAccounts = accounts.filter { (account) -> Bool in
      return accountManager.mnemonic(for: account.address) != nil
    }
    return newAccounts
  }

  func selectedAccount() -> Account? {
    return accounts().first
  }

  func hasAccount() -> Bool {
    return accounts().count > 0
  }

  func deleteAllAccounts() {
    
  }

  func addAccount(mnemonic: String) {
    guard let address = accountManager.address(from: mnemonic) else {
      return
    }

    do {
      try accountManager.saveMnemonic(mnemonic: mnemonic)
    } catch {
      return
    }
    let accounts = databaseStorage.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]

    //No repeated accounts allowed
    guard (accounts ?? []).filter({ (acc) -> Bool in
      return acc.address == address
    }).count == 0 else {
      return
    }

    let dbModel = AccountDataBaseModel()
    dbModel.address = address
    dbModel.encryptedBy = Account.EncryptedBy.me.rawValue
    dbModel.isMain = true
    databaseStorage.add(object: dbModel)
  }

  func logout() {
    storage.removeAll()
  }

  // MARK: - AuthStateProvider

  var authState: AuthState {
    return self.hasAccount() ? .hasAccount : .noAccount
  }
}

extension LocalStorageAuthService {

  convenience init() {
    let storage = SecureStorage(namespace: "Auth")
    let accountManager = AccountManager()
    self.init(storage: storage, accountManager: accountManager)
  }

}
