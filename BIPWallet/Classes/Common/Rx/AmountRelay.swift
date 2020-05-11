//
//  AmountRelay.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxBiBinding

class AmountHelper {

//  let proxySubject = BehaviorRelay<String?>(value: nil)

//  class func amountRelay(value: String? = nil) -> BehaviorRelay<String?> {
//    return BehaviorRelay<String?>(value: value).map { (val) -> String? in
//      return Self.transformValue(value: val)
//    }
//  }
//
//  class func amountSubject(value: String? = nil) -> BehaviorSubject<String?> {
//    return BehaviorSubject<String?>(value: value).map { (val) -> String? in
//      return Self.transformValue(value: val)
//    }
//  }
//
  class func transformValue(value: String?) -> String? {
    var newValue = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
    if newValue?.starts(with: ".") ?? false {
      newValue = "0." + (newValue?.trimmingCharacters(in: CharacterSet(charactersIn: ".")) ?? "")
    }
    return newValue
  }

}


//public final class AmountRelay: ObservableType {
//  public typealias Element = String?
//
//  private let _subject: BehaviorSubject<Element>
//
//  /// Accepts `event` and emits it to subscribers
//  public func accept(_ event: Element) {
//
//    self._subject.onNext(event)
//  }
//
//  /// Current value of behavior subject
//  public var value: Element {
//    // this try! is ok because subject can't error out or be disposed
//    return try! self._subject.value()
//  }
//
//  /// Initializes behavior relay with initial value.
//  public init(value: Element) {
//
//    self._subject = BehaviorSubject(value: value)
//  }
//
//  /// Subscribes observer
//  public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Element == Element {
//    return self._subject.subscribe(observer)
//  }
//
//  /// - returns: Canonical interface for push style sequence
//  public func asObservable() -> Observable<Element> {
//    return self._subject.asObservable()
//  }
//
//  fileprivate func transformValue(value: String?) -> String? {
//    var newValue = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
//    if newValue?.starts(with: ".") ?? false {
//      newValue = "0." + (newValue?.trimmingCharacters(in: CharacterSet(charactersIn: ".")) ?? "")
//    }
//    return newValue
//  }
//
//}
//
////public func <-><E>(left: ControlProperty<E>, right: AmountRelay) -> Disposable {
////  let leftChannel = RxChannel<E>(withProperty: left)
////  let rightChannel = RxChannel<E>.init(withBehaviorRelay: right)
////
////  return CompositeDisposable.init(leftChannel, rightChannel, leftChannel & rightChannel)
////}
