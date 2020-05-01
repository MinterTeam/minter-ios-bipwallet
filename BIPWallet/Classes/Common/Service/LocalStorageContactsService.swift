//
//  LocalStorageContactsService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

enum LocalStorageContactsServiceError: Error {
  case incorrectParam
  case cantFindItem
  case cantDeleteItem
}

class LocalStorageContactsService: ContactsService {

  let storage: DatabaseStorage

  init(storage: DatabaseStorage = RealmDatabaseStorage.shared) {
    self.storage = storage
  }

  func contacts() -> Observable<[ContactItem]> {
    return Observable<[ContactItem]>.create { (observer) -> Disposable in
      DispatchQueue.main.async {
        let objects = (self.storage.objects(class: ContactEntryDataBaseModel.self, query: nil) as? [ContactEntryDataBaseModel]) ?? []
        let conts = objects.map { (model) -> ContactItem in
          return ContactItem(name: model.name, address: model.address)
        }
        observer.onNext(conts)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func add(item: ContactItem) throws -> Observable<Void> {
    guard let name = item.name, let address = item.address else {
      throw ContactsServiceError.incorrectParam
    }

    return Observable<Void>.create { (observer) -> Disposable in
      let res = self.storage.objects(class: ContactEntryDataBaseModel.self, query: "name contains[c] '\(name.lowercased())' or address='\(address)'") ?? []
      if !res.isEmpty {
        observer.onError(ContactsServiceError.dublicateContact)
      } else {
        let contactObject = ContactEntryDataBaseModel()
        contactObject.address = address
        contactObject.name = name
        do {
          try self.storage.add(object: contactObject)
          observer.onNext(Void())
        } catch {
          observer.onError(ContactsServiceError.cantSaveContact)
        }
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func contact(by name: String) -> Observable<ContactItem?> {
    return Observable.create { (observer) -> Disposable in
      let res = self.storage.objects(class: ContactEntryDataBaseModel.self,
                                     query: "name contains[c] '\(name.lowercased())'") ?? []

      if let model = res.first as? ContactEntryDataBaseModel {
        let contact = ContactItem(name: model.name, address: model.address)
        observer.onNext(contact)
      } else {
        observer.onNext(nil)
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func delete(_ item: ContactItem) -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let name = item.name ?? ""
      let address = item.address ?? ""
      if let res = (self.storage.objects(class: ContactEntryDataBaseModel.self, query: "name contains[c] '\(name.lowercased())' AND address='\(address)'") ?? []).first {
        do {
          try self.storage.delete(object: res)
          observer.onNext(())
        } catch {
          observer.onError(LocalStorageContactsServiceError.cantDeleteItem)
        }
      } else {
        observer.onError(LocalStorageContactsServiceError.cantFindItem)
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func edit(_ old: ContactItem, newItem: ContactItem) throws -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      guard let oldName = old.name, let oldAddress = old.address, let name = newItem.name, let address = newItem.address else {
        observer.onError(LocalStorageContactsServiceError.incorrectParam)
        return Disposables.create()
      }

      let addOld = {
        let contactObject = ContactEntryDataBaseModel()
        contactObject.address = oldAddress
        contactObject.name = oldName
        do {
          try self.storage.add(object: contactObject)
        } catch {
          observer.onError(LocalStorageContactsServiceError.cantDeleteItem)
        }
      }

      //Removing the old one
      if let res = (self.storage.objects(class: ContactEntryDataBaseModel.self, query: "name contains[c] '\(oldName.lowercased())' AND address='\(oldAddress)'") ?? []).first {
        do {
          try self.storage.delete(object: res)
        } catch {
          observer.onError(LocalStorageContactsServiceError.cantDeleteItem)
          return Disposables.create()
        }
      }

      let res = self.storage.objects(class: ContactEntryDataBaseModel.self, query: "name contains[c] '\(name.lowercased())' or address='\(address)'") ?? []
      if res.count > 0 {
        observer.onError(ContactsServiceError.dublicateContact)
        addOld()
      } else {
        let contactObject = ContactEntryDataBaseModel()
        contactObject.address = address
        contactObject.name = name
        do {
          try self.storage.add(object: contactObject)
          observer.onNext(Void())
        } catch {
          observer.onError(ContactsServiceError.cantSaveContact)
          addOld()
        }
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }

}
