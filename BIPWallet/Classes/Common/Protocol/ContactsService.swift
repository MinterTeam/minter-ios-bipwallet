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
  func contact(by name: String) -> Observable<ContactItem?>
  func delete(_ item: ContactItem) -> Observable<Void>
}
