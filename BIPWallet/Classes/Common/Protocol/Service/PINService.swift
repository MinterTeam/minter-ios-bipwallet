//
//  PINService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import LocalAuthentication

protocol PINService {
  func hasPIN() -> Bool
  func canUseBiometric() -> Bool
  func biometricType() -> LABiometryType
  func setPIN(code: String)
  func removePIN()
  func checkPIN(code: String) -> Bool
  func checkBiometricsIfPossible(with completion: ((Bool) -> ())?)
  func isBiometricEnabled() -> Bool
  func setBiometric(enabled: Bool)
  func setPINAttempts(attempts: Int)
  func getPINAttempts() -> Int
  func isUnlocked() -> Bool
  func unlock(with code: String) throws -> Bool
  func unlockWithBiometrics()
}
