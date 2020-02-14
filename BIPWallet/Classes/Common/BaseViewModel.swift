//
//  BaseViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewModel {
  associatedtype Input
  associatedtype Output
  associatedtype Dependency

  var input: Input! { get }
  var output: Output! { get }
  var dependency: Dependency! { get }
}

class BaseViewModel {
  var disposeBag = DisposeBag()
}
