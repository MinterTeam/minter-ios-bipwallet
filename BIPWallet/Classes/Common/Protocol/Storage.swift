//
//  Storage.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation

public protocol Storage {
  func set<T: AnyObject>(_ object: T, forKey key: String) where T: NSCoding
  func set(_ data: Data, forKey key: String)
  func set(_ bool: Bool, forKey key: String)

  func object(forKey key: String) -> Any?
  func bool(forKey key: String) -> Bool?

  func removeObject(forKey key: String)
  func removeAll()
}
