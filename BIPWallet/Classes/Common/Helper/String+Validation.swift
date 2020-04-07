//
//  String+Validation.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension String {

  func isValidAddress() -> Bool {
    let addressTest = NSPredicate(format: "SELF MATCHES %@", "^[a-fA-F0-9]{40}$")
    return addressTest.evaluate(with: self.stripMinterHexPrefix())
  }

  func isValidPublicKey() -> Bool {
    let publicKeyTest = NSPredicate(format: "SELF MATCHES %@", "^[a-fA-F0-9]{64}$")
    return publicKeyTest.evaluate(with: self.stripMinterHexPrefix())
  }

	static func isUsernameValid(_ username: String) -> Bool {
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^[@]?[a-zA-Z0-9_]{5,16}")
		return usernameTest.evaluate(with: username)
	}

	static func isPhoneValid(_ phone: String) -> Bool {
		let reg = "(\\+[0-9]+[\\- \\.]*)?([0-9][0-9\\- \\.]+[0-9])"
		let phoneTest = NSPredicate(format:"SELF MATCHES %@", reg)
		return phoneTest.evaluate(with: phone)
	}

	func isValidContactName() -> Bool {
		let usernameTest = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9_]{3,18}")
		return usernameTest.evaluate(with: self)
	}

	func isValidCoin() -> Bool {
		return self.count >= 3
	}
}
