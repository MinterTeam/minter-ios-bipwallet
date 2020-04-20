//
//  AccountService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore

protocol AccountService {

  func privateKey(for account: AccountItem) -> PrivateKey?

}
