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
import RxSwift

final class LocalStorageAuthService: AuthService {

  // Storage to store PKs
  private let storage: Storage
  // Manager to manage DB records
  private let accountManager: AccountManager
  private let databaseStorage = RealmDatabaseStorage.shared
  private let pinService: PINService

  init(storage: Storage, accountManager: AccountManager, pinService: PINService) {
    self.storage = storage
    self.accountManager = accountManager
    self.pinService = pinService
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
    return accounts().sorted(by: { (item1, item2) -> Bool in
      return item1.lastSelected > item2.lastSelected
    }).first
  }

  func hasAccount() -> Bool {
    return accounts().count > 0
  }

  func deleteAllAccounts() {}

  func addAccount(mnemonic: String, title: String?) throws -> AccountItem? {
    guard let address = accountManager.address(from: mnemonic) else {
      throw AuthServiceError.invalidMnemonic
    }

    let accounts = databaseStorage.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]

    //No repeated accounts allowed
    guard (accounts ?? []).filter({ (acc) -> Bool in
      if acc.address == address { return true }
      return (title != nil ? (acc.title == title) : false)
    }).count == 0 else {
      throw AuthServiceError.dublicateAddress
    }

    do {
      try accountManager.saveMnemonic(mnemonic: mnemonic)
    } catch {
      throw AuthServiceError.unknown
    }

    let newTitle = title ?? "Mx" + TransactionTitleHelper.title(from: address)

    let dbModel = AccountDataBaseModel()
    dbModel.address = address
    dbModel.title = newTitle

    do {
      try databaseStorage.add(object: dbModel)
    } catch {
      throw AuthServiceError.unknown
    }
    return AccountItem(title: newTitle, address: address)
  }

  func logout() {
    storage.removeAll()
    databaseStorage.removeAll()
    accountManager.setRandomEncryptionKeyIfNotExists()
  }

  // MARK: - AuthStateProvider

  var authState: AuthState {
    return self.hasAccount() ? (!self.pinService.isUnlocked() ? .pinNeeded : .hasAccount) : .noAccount
  }
}

extension LocalStorageAuthService {

  func updateAccount(account: AccountItem) -> Observable<Void> {
    return Observable<Void>.create { (observer) -> Disposable in
      let accounts = self.databaseStorage.objects(class: AccountDataBaseModel.self, query: "address='\(account.address.stripMinterHexPrefix())'") as? [AccountDataBaseModel]
      if let dbAccount = accounts?.first {
        self.databaseStorage.update {
          dbAccount.emoji = account.emoji
          dbAccount.title = account.title
          dbAccount.lastSelected = account.lastSelected.timeIntervalSince1970
          observer.onNext(())
          observer.onCompleted()
        }
      } else {
        observer.onError(AuthServiceError.unknown)
      }
      return Disposables.create()
    }
  }

  func addAccount(with mnemonic: String, title: String?) -> Observable<AccountItem> {
    return Observable<AccountItem>.create { (observer) -> Disposable in
      DispatchQueue.global().async {
        guard let address = self.accountManager.address(from: mnemonic) else {
          observer.onError(AuthServiceError.invalidMnemonic)
          return
        }

        DispatchQueue.main.async {
          let accounts = self.databaseStorage.objects(class: AccountDataBaseModel.self, query: "address='\(address.stripMinterHexPrefix())'") as? [AccountDataBaseModel]

          //No repeated accounts allowed
          guard (accounts ?? []).filter({ (acc) -> Bool in
            if acc.address == address { return true }
            return (title != nil ? (acc.title == title) : false)
          }).count == 0 else {
            observer.onError(AuthServiceError.dublicateAddress)
            return
          }

          do {
            try self.accountManager.saveMnemonic(mnemonic: mnemonic)
          } catch {
            observer.onError(AuthServiceError.unknown)
            return
          }

          let newTitle = title// ?? "Mx" + TransactionTitleHelper.title(from: address)

          let dbModel = AccountDataBaseModel()
          dbModel.address = address
          dbModel.title = newTitle

          do {
            try self.databaseStorage.add(object: dbModel)
          } catch {
            observer.onError(AuthServiceError.unknown)
            return
          }
          observer.onNext(AccountItem(title: newTitle, address: address))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

}
