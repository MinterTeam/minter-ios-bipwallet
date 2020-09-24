//
//  ExplorerValidatorService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

class ExplorerValidatorService: ValidatorService {

  private let disposeBag = DisposeBag()

  private var validatorsSubject = ReplaySubject<[ValidatorItem]>.create(bufferSize: 1)

  private lazy var manager = MinterExplorer.ValidatorManager(httpClient: APIClient.shared)

  func validators() -> Observable<[ValidatorItem]> {
    return validatorsSubject.asObservable()
  }

  @LocalStorage("ExplorerValidatorServiceLastUsed", defaultValue: nil)
  var lastUsedPublicKey: String?

  func updateValidators() {
    self.update().map({ (resp) -> [ValidatorItem] in
      return resp.filter({ (response) -> Bool in
        return response.publicKey != nil && response.publicKey?.stringValue.isValidPublicKey() ?? false
      }).map { (response) -> ValidatorItem in
        var item = ValidatorItem(publicKey: response.publicKey!.stringValue,
                                 name: response.name)
        item?.iconURL = response.iconURL
        item?.isOnline = response.status == .ready
        item?.stake = response.stake ?? 0.0
        item?.minStake = response.minStake ?? 0.0
        item?.commission = response.commission
        return item!
      }
    }).subscribe(validatorsSubject).disposed(by: disposeBag)
  }

  func update() -> Observable<[ValidatorInfoResponse]> {
    return Observable.create { (observer) -> Disposable in
      self.manager.validators { (response, error) in
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
