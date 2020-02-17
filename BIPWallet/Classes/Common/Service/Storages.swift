//
//  Storage.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import KeychainSwift

class LocalStorage: Storage {

  private var storage = UserDefaults.standard

  func set<T : AnyObject>(_ object: T, forKey key: String) where T : NSCoding {
    //archive key
    let data = NSKeyedArchiver.archivedData(withRootObject: object)
    storage.set(data, forKey: key)
    storage.synchronize()
  }

  func set(_ data: Data, forKey key: String) {
    storage.set(data, forKey: key)
    storage.synchronize()
  }

  func set(_ bool: Bool, forKey key: String) {
    storage.set(bool, forKey: key)
    storage.synchronize()
  }

  func allKeys() -> [String]? {
    return nil
  }

  func object(forKey key: String) -> Any? {
    if let obj = self.storage.object(forKey: key) as? Data {
      return NSKeyedUnarchiver.unarchiveObject(with: obj)
    }
    return nil
  }

  func bool(forKey key: String) -> Bool? {
    return self.storage.bool(forKey: key)
  }

  func removeObject(forKey key: String) {
    storage.removeObject(forKey: key)
    storage.synchronize()
  }

  func removeAll() {
    storage.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    storage.synchronize()
  }
}

class SecureStorage: Storage {

  // MARK: -

  init(namespace: String = "SecureStorage") {
    self.namespace = namespace
    storage = KeychainSwift(keyPrefix: namespace)
  }

  let namespace: String

  private let storage: KeychainSwift

  // MARK: - Setters

  func set(_ bool: Bool, forKey key: String) {
    storage.set(bool, forKey: key)
  }

  func set<T>(_ object: T, forKey key: String) where T : AnyObject, T : NSCoding {
    let archive = NSKeyedArchiver.archivedData(withRootObject: object)
    storage.set(archive, forKey: key)
  }

  func set(_ data: Data, forKey key: String) {
    let archive = NSKeyedArchiver.archivedData(withRootObject: data)
    storage.set(archive, forKey: key)
  }

  // MARK: - Getters

  func allKeys() -> [String]? {
    return storage.allKeys
  }

  func object(forKey key: String) -> Any? {
    guard let archive = storage.getData(key) else {
      return nil
    }
    let res = NSKeyedUnarchiver.unarchiveObject(with: archive)
    return res
  }

  func bool(forKey key: String) -> Bool? {
    return storage.getBool(key)
  }

  // MARK: - Remove

  //Removes all keychain items
  func removeAll() {
    storage.clear()
  }

  func removeObject(forKey key: String) {
    storage.delete(key)
  }

}
