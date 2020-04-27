//
//  RawTransactionViewModelProtocol.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 29/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift

protocol RawTransactionViewModelAccountProtocol: class {
  func privatekey(for address: String) throws -> String
}

protocol RawTransactionViewModelGateProtocol: class {
	func nonce(address: String) -> Observable<Int>
	func minGas() -> Observable<Int>
	func send(rawTx: String?) -> Observable<String?>
}

class RawTransactionViewModelAccount: RawTransactionViewModelAccountProtocol {

	private var accountManager = AccountManager()

	enum RawTransactionViewModelAccountError: Error {
		case noAccount
	}

	func address() throws -> String {
    fatalError("Override me")
	}

  func privatekey(for address: String) throws -> String {
		guard
      let mnemonic = self.accountManager.mnemonic(for: address.stripMinterHexPrefix()),
			let seed = self.accountManager.seed(mnemonic: mnemonic),
			let privateKey = try? self.accountManager.privateKey(from: seed).raw.toHexString()
			else {
				throw RawTransactionViewModelAccountError.noAccount
		}
		return privateKey
	}
}

extension GateManager: RawTransactionViewModelGateProtocol {}
