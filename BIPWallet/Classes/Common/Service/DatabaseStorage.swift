//
//  DatabaseStorage.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 14/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RealmSwift

protocol DatabaseStorageModel: Object {}

protocol DatabaseStorage {
  func add(object: DatabaseStorageModel) throws
  func objects(class cls: DatabaseStorageModel.Type, query: String?) -> [DatabaseStorageModel]?
  func delete(object: DatabaseStorageModel) throws
  func update(old: DatabaseStorageModel, new: DatabaseStorageModel) throws
  func update(updates: (() -> ())?) throws
}

class RealmDatabaseStorage: DatabaseStorage {

	private init() {}

	static let shared = RealmDatabaseStorage()

	// MARK: -

	private let realm = try! Realm()// swiftlint:disable:this force_try

	// MARK: -

	func add(object: DatabaseStorageModel) throws {
		guard let obj = object as? Object else {
			assert(true, "Should be an instance of Object")
			return
		}

		try! realm.write {// swiftlint:disable:this force_try
      realm.add(obj, update: .error)
		}
	}

  func update(old: DatabaseStorageModel, new: DatabaseStorageModel) throws {
    guard let oldObj = old as? Object, let newObj = new as? Object  else {
      assert(true, "Should be an instance of Object")
      return
    }
  }

  func update(updates: (() -> ())?) throws {
    try! realm.write {// swiftlint:disable:this force_try
      updates?()
    }
  }

	// MARK: -

	func objects(class cls: DatabaseStorageModel.Type, query: String? = nil) -> [DatabaseStorageModel]? {
		guard let clss = cls as? Object.Type else {
			return nil
		}

		var results = realm.objects(clss)
		if nil != query {
			results = results.filter(query!)
		}
		return Array(results) as? [DatabaseStorageModel]
	}

	// MARK: -

	func update(updates: (() -> ())) {
		try! realm.write {// swiftlint:disable:this force_try
			updates()
		}
	}
  
  func delete(object: DatabaseStorageModel) throws {
    try! realm.write {// swiftlint:disable:this force_try
      realm.delete(object)
    }
  }

	// MARK: -

	func removeAll() {
		try! realm.write {// swiftlint:disable:this force_try
			realm.deleteAll()
		}
	}

  func removeAllObjectsOf(type: DatabaseStorageModel.Type) {
    let objectsToDelete = self.objects(class: type) ?? []
    guard objectsToDelete.count > 0 else { return }

    try! realm.write {// swiftlint:disable:this force_try
      realm.delete(objectsToDelete)
    }
  }

}
