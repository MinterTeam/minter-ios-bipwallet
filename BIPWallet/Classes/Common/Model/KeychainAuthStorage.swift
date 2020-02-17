//
//  AuthStorage.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

class KeychainAuthStorage: AuthStorage {

  private enum AuthStorageKey: String {
    case accounts
  }

  private let storage = SecureStorage(namespace: "Auth")

  func hasAccounts() -> Bool {
    guard let accounts = storage.allKeys() else { return false }
    print(accounts)
    
    
//    do {
//      let accounts = try JSONDecoder().decode([String: String](), from: accountsData)
//      return !accounts.isEmpty
//    } catch {
//
//    }
    return false
  }

//  func save(address: String, mnemonic: String, completion: ((Bool) -> ())?) {
//    var accounts = Set(storage.object(forKey: AuthStorageKey.accounts.rawValue) as? [[String: String]] ?? [])
//    accounts.insert(["address": address, "mnemonic": mnemonic])
//    do {
//      let encoded = try JSONEncoder().encode(Array<[String: String]>(accounts))
//      storage.set(encoded, forKey: AuthStorageKey.accounts.rawValue)
//      completion?(false)
//    } catch {
//      completion?(false)
//    }
//  }

  func deleteAllAccounts() {
    
  }
}
