//
//  RecipientInfoService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 28.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import RxSwift

protocol RecipientInfoService {
  func title(for recipient: String) -> String?
  func avatarURL(for recipient: String) -> URL?
  func isReady() -> Observable<Bool>
}

class ExplorerRecipientInfoService: RecipientInfoService {

  // MARK: - RecipientInfoService

  func isReady() -> Observable<Bool> {
    return isReadySubject.asObservable()
  }

  func title(for recipient: String) -> String? {
    return infoTitleItems[recipient.stripMinterHexPrefix()]
  }

  func avatarURL(for recipient: String) -> URL? {
    return infoAvatarItems[recipient.stripMinterHexPrefix()]
  }

  // MARK: -

  var disposeBag = DisposeBag()

  private let isReadySubject = BehaviorSubject<Bool>(value: false)

  let contactsService: ContactsService
  let validatorManager = MinterExplorer.ValidatorManager(httpClient: APIClient())

  var infoTitleItems = [String: String]()
  var infoAvatarItems = [String: URL]()

  init(contactsService: ContactsService) {
    self.contactsService = contactsService

    Observable.combineLatest(loadValidators(), contactsService.contacts()).do(onNext: { (items) in
      items.0.forEach { (item) in
        if let publicKey = item.publicKey?.stringValue {
          if let name = item.name {
            self.infoTitleItems[publicKey.stripMinterHexPrefix()] = item.name
          }
          if let iconURL = item.iconURL {
            self.infoAvatarItems[publicKey.stripMinterHexPrefix()] = iconURL
          }
        }
      }
 
      items.1.forEach { (item) in
        if let address = item.address {
          self.infoTitleItems[address.stripMinterHexPrefix()] = item.name ?? address
        }
      }
    }).map({ (items) -> Bool in
      return true
      }).subscribe(isReadySubject).disposed(by: disposeBag)
  }

  let validators = [String: String]()

  private func loadValidators() -> Observable<[ValidatorInfoResponse]> {
    return Observable.create { (observer) -> Disposable in
      self.validatorManager.validators { (response, error) in
        guard error == nil else {
          observer.onError(error!)
          return
        }
        observer.onNext(response ?? [])
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

}
