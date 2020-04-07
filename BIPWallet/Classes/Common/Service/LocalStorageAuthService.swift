//
//  LocalStorageAuthService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy

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
  
  func accounts() -> [AccountItem] {
    guard let accounts = accountManager.loadLocalAccounts(), accounts.count > 0 else {
      return []
    }

    let newAccounts = accounts.filter { (account) -> Bool in
      return accountManager.mnemonic(for: account.address) != nil
    }
    return newAccounts
  }

  func selectedAccount() -> AccountItem? {
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
    dbModel.title = TransactionTitleHelper.title(from: address)
//    dbModel.encryptedBy = Account.EncryptedBy.me.rawValue
    do {
      try databaseStorage.add(object: dbModel)
    } catch {
      return
    }
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
