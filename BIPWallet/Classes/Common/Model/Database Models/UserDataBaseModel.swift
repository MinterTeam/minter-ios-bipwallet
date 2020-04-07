//
//  UserDataBaseModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 05.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RealmSwift
import MinterMy

class UserDataBaseModel: Object, DatabaseStorageModel {

  @objc dynamic var id: Int = -1
  @objc dynamic var name: String = ""
  @objc dynamic var username: String = ""
  @objc dynamic var email: String = ""
  @objc dynamic var phone: String = ""
  @objc dynamic var language: String = ""
  @objc dynamic var avatar: String = ""

  //MARK: -

  func substitute(with user: User) {
    self.id = user.id ?? -1
    self.username = user.username ?? ""
    self.email = user.email ?? ""
  }
}

extension User {

  convenience init(dbModel: UserDataBaseModel) {
    self.init()

    self.id = dbModel.id
    self.username = dbModel.username
    self.email = dbModel.email
    self.language = dbModel.language
    self.avatar = dbModel.avatar
  }

}
