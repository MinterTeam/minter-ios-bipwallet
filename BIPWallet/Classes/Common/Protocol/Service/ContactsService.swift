//
//  ContactsService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

enum ContactsServiceError: Error {
  case incorrectParam
  case cantSaveContact
  case dublicateContact
}

protocol ContactsService {
  func contacts() -> Observable<[ContactItem]>
  func add(item: ContactItem) throws -> Observable<Void>
  func edit(_ old: ContactItem, newItem: ContactItem) throws -> Observable<Void>
  /// Contact by name
  func contactBy(name: String) -> Observable<ContactItem?>
  /// Contact by address
  func contactBy(address: String) -> Observable<ContactItem?>
  func delete(_ item: ContactItem) -> Observable<Void>
  func contactsChanged() -> Observable<Void>
  var lastUsedAddress: String? {get set}
}
