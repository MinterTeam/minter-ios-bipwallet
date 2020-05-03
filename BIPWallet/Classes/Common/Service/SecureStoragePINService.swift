//
//  PINManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/07/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import LocalAuthentication
import RxSwift

enum SecureStoragePINServiceError: Error {
  case PINMaxAttemptsExceeded
}

class SecureStoragePINService: PINService {

  let PINRequiredMinimumSeconds = 5.0//60.0 * 2.0
  let PINMaxAttempts = 3

  init() {
//    Observable.of(UIApplication.shared.rx.applicationDidBecomeActive.map {$0 as AnyObject},
//                  UIApplication.shared.rx.applicationOpenWithURL.asObservable().map {$0 as AnyObject }).merge()
    UIApplication.shared.rx.applicationDidBecomeActive
      .subscribe(onNext: { [weak self] (_) in
        guard let `self` = self else { return }
        if let backgroundDate = self.lastBackgroundDate, self.hasPIN() {
          if backgroundDate.timeIntervalSinceNow < -self.PINRequiredMinimumSeconds {
            self.unlocked = false
          } else {
            self.unlocked = true
          }
        }
        self.lastBackgroundDate = nil
      }).disposed(by: disposeBag)

    UIApplication.shared.rx.applicationDidEnterBackground
      .subscribe(onNext: { [weak self] (_) in
        self?.lastBackgroundDate = Date()
        //Blocking on enter to the background, but it can be automatically unlocked
        self?.unlocked = false
      }).disposed(by: disposeBag)
  }

  // MARK: -

  enum StorageKeys: String {
    case pin
    case lastDate
    case biometricEnabled
    case attemptNumberKey
  }

	// MARK: -

  var disposeBag = DisposeBag()

  var lastBackgroundDate: Date?

  private var storage = SecureStorage()

  func hasPIN() -> Bool {
    return nil != (storage.object(forKey: StorageKeys.pin.rawValue) as? Data)
  }

	// MARK: -

  private var unlocked = false

  func isUnlocked() -> Bool {
    return !self.hasPIN() || unlocked
  }

  func removePIN() {
    storage.removeObject(forKey: StorageKeys.pin.rawValue)
  }

  func setPIN(code: String) {
    if let data = data(from: code) {
      storage.set(data, forKey: StorageKeys.pin.rawValue)
    }
  }

  func checkPIN(code: String) -> Bool {
    if let object = storage.object(forKey: StorageKeys.pin.rawValue) as? Data {
      return object == data(from: code)
    }
    return false
  }

  func unlock(with code: String) throws -> Bool {
    if checkPIN(code: code) {
      self.unlocked = true
      self.setPINAttempts(attempts: 0)
      return true
    } else {
      let attempts = self.getPINAttempts()
      if attempts > PINMaxAttempts {
        throw SecureStoragePINServiceError.PINMaxAttemptsExceeded
      }
      self.setPINAttempts(attempts: attempts+1)
    }
    return false
  }

  func unlockWithBiometrics() {
    self.unlocked = true
    self.setPINAttempts(attempts: 0)
  }

  func setPINAttempts(attempts: Int) {
    storage.set(String(attempts).data(using: .utf8) ?? Data(),
                      forKey: StorageKeys.attemptNumberKey.rawValue)
  }

  func getPINAttempts() -> Int {
    let attempts = storage.object(forKey: StorageKeys.attemptNumberKey.rawValue) as? Data
    let str = String(data: attempts ?? Data(), encoding: .utf8) ?? ""
    return Int(str) ?? 0
  }

  // MARK: -

  private func data(from code: String) -> Data? {
    return code.sha256().data(using: .utf8)
  }

	// MARK: - LocalAuth

  private var authContext = LAContext()

  func canUseBiometric() -> Bool {
    return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }

  @available(iOS 11.0, *)
  func biometricType() -> LABiometryType {
    return authContext.biometryType
  }

  func isBiometricEnabled() -> Bool {
    return storage.bool(forKey: StorageKeys.biometricEnabled.rawValue) ?? false
  }

  func setBiometric(enabled: Bool) {
    storage.set(enabled, forKey: StorageKeys.biometricEnabled.rawValue)
  }

  func checkBiometricsIfPossible(with completion: ((Bool) -> ())?) {
    if self.canUseBiometric() {
      self.authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                      localizedReason: "To enter to the wallet",
                                      reply: { [weak self] (res, err) in
                                        self?.authContext.invalidate()
                                        self?.authContext = LAContext()
                                        completion?(res)
      })
    }
  }

}
