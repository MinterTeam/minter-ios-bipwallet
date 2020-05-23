//
//  BaseViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

enum ImpactType {
  case light
  case hard
}

protocol ViewModel {
  associatedtype Input
  associatedtype Output
  associatedtype Dependency

  var input: Input! { get }
  var output: Output! { get }
  var dependency: Dependency! { get }

  var impact: PublishSubject<ImpactType> { get set }
  var sound: PublishSubject<SoundType> { get set }
  var showErrorMessage: PublishSubject<String> { get set }
  var showSuccessMessage: PublishSubject<String> { get set }
  var showNotifyMessage: PublishSubject<String> { get set }
}

class BaseViewModel {

  var disposeBag = DisposeBag()

  var impact = PublishSubject<ImpactType>()
  var sound = PublishSubject<SoundType>()
  var showErrorMessage = PublishSubject<String>()
  var showSuccessMessage = PublishSubject<String>()
  var showNotifyMessage = PublishSubject<String>()

}
