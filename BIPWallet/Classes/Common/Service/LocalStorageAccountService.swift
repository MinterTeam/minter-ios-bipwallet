//
//  LocalStorageAccountService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore

class LocalStorageAccountService: AccountService {

  private let accountManager = AccountManager()

  func privateKey(for account: AccountItem) -> PrivateKey? {
    return accountManager.privateKey(for: account.address)
  }

}
