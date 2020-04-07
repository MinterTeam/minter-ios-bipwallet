//
//  AccountDataBaseModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 15/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RealmSwift
import MinterMy

class AccountDataBaseModel: Object, DatabaseStorageModel {

  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var emoji: String = "🐠"
  @objc dynamic var title: String = ""
  @objc dynamic var address: String = ""

  override static func primaryKey() -> String? {
    return "id"
  }

	// MARK: -

	func substitute(with account: AccountItem) {
    self.emoji = account.emoji
    self.title = account.title
		self.address = account.address
	}

}
