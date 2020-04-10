//
//  AuthService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 12.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterMy
import RxSwift

enum AuthState {
  case noAccount
  case pinNeeded
  case hasAccount
}

protocol AuthStateProvider {
  var authState: AuthState { get }
}

enum AuthServiceError: Error {
  case invalidMnemonic
  case dublicateAddress
  case titleTaken
  case unknown
}

protocol AuthService {
  func accounts() -> [AccountItem]
  func hasAccount() -> Bool
  func addAccount(mnemonic: String, title: String?) throws -> AccountItem?
  func addAccount(with mnemonic: String, title: String?) -> Observable<AccountItem>
  func updateAccount(account: AccountItem) -> Observable<Void>
  func logout()
}
