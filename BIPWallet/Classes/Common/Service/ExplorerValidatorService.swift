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

  private var validatorsSubject = PublishSubject<[ValidatorItem]>()

  private lazy var manager = MinterExplorer.ValidatorManager(httpClient: APIClient.shared)

  func validators() -> Observable<[ValidatorItem]> {
    return validatorsSubject.asObservable()
  }

  func updateValidators() {
    self.update().map({ (resp) -> [ValidatorItem] in
      return resp.filter({ (response) -> Bool in
        return response.publicKey != nil
      }).map { (response) -> ValidatorItem in
        let item = ValidatorItem(publicKey: response.publicKey!.stringValue, name: response.name)
        return item
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
