//
//  ContactEntryDataBaseModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 28.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RealmSwift

class ContactEntryDataBaseModel: Object, DatabaseStorageModel {

  @objc dynamic var contactId: String = UUID().uuidString
  @objc dynamic var name: String = ""
  @objc dynamic var address: String = ""

  override static func primaryKey() -> String? {
    return "contactId"
  }

}
