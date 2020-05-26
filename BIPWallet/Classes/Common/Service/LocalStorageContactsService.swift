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

  private var contactsChangedSubject = PublishSubject<Void>()

  func contactsChanged() -> Observable<Void> {
    return contactsChangedSubject.asObservable()
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
      self.contactsChangedSubject.onNext(())
      return Disposables.create()
    }
  }

  func contactBy(name: String) -> Observable<ContactItem?> {
    return Observable.create { (observer) -> Disposable in
      let res = (self.storage.objects(class: ContactEntryDataBaseModel.self,
                                     query: nil) ?? [])
      .filter { (model) -> Bool in
        return (model as? ContactEntryDataBaseModel)?.name.lowercased() == name.lowercased()
      }
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

  func contactBy(address: String) -> Observable<ContactItem?> {
    return Observable.create { (observer) -> Disposable in
      let res = (self.storage.objects(class: ContactEntryDataBaseModel.self,
                                     query: nil) ?? [])
      .filter { (model) -> Bool in
        return (model as? ContactEntryDataBaseModel)?.address.stripMinterHexPrefix().lowercased() == address.lowercased().stripMinterHexPrefix()
      }
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
      if let res = (self.storage.objects(class: ContactEntryDataBaseModel.self, query: "address='\(address)'") ?? []).first {
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
      self.contactsChangedSubject.onNext(())
      return Disposables.create()
    }
  }

  func edit(_ old: ContactItem, newItem: ContactItem) throws -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      guard let oldName = old.name, let oldAddress = old.address, let name = newItem.name, let address = newItem.address else {
        observer.onError(LocalStorageContactsServiceError.incorrectParam)
        return Disposables.create()
      }

      let res = self.storage.objects(class: ContactEntryDataBaseModel.self, query: "address != '\(oldAddress)'") ?? []
      guard res.filter({ (model) -> Bool in
        guard let contactModel = (model as? ContactEntryDataBaseModel) else { return false }
        let addressBool = (contactModel.address == address)
        let nameBool = contactModel.name.lowercased() == name.lowercased()

        return addressBool || nameBool
      }).count == 0 else {
        observer.onError(ContactsServiceError.dublicateContact)
        return Disposables.create()
      }

      if let res = (self.storage.objects(class: ContactEntryDataBaseModel.self,
                                         query: "address='\(oldAddress)'") ?? []).first as? ContactEntryDataBaseModel {
        if let address = newItem.address, let name = newItem.name {
          do {
            try self.storage.update(updates: {
              res.address = address
              res.name = name
            })
          } catch {
            observer.onError(LocalStorageContactsServiceError.cantDeleteItem)
            return Disposables.create()
          }
          observer.onNext(())
          observer.onCompleted()
          self.contactsChangedSubject.onNext(())
        }
      }
      observer.onError(ContactsServiceError.cantSaveContact)
      return Disposables.create()
    }
  }

}
