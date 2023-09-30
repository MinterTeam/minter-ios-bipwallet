import Foundation
import CryptoSwift
import MinterCore
import MinterMy

class AccountManager {

	init(secureStorage: Storage = SecureStorage()) {
        self.secureStorage = secureStorage
        setRandomEncryptionKeyIfNotExists()
	}

	enum AccountManagerError: Error {
    case noEncryptionKey
		case privateKeyUnableToEncrypt
		case privateKeyEncryptionFaulted
		case privateKeyCanNotBeSaved
	}

	// MARK: - Sources

	private let database = RealmDatabaseStorage.shared
	private let secureStorage: Storage

	// MARK: -

	private let encryptionKeyKey = "AccountPassword"
	private let iv = Data(bytes: "Minter seed".bytes).setLengthRight(16)

	// MARK: -
	//Account with seed
	func accountPassword(_ password: String) -> String {
		return password.sha256().sha256()
	}

	func account(id: Int, mnemonic: String, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		guard let seed = seed(mnemonic: mnemonic) else {
			return nil
		}
		return account(id: id, seed: seed, encryptedBy: encryptedBy)
	}

	func account(id: Int, seed: Data, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		guard
			let newPk = try? self.privateKey(from: seed),
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		var acc = Account(id: id, encryptedBy: .me, address: address)
		acc.encryptedBy = encryptedBy
		return acc
	}

	func privateKey(from seed: Data) throws -> PrivateKey {
		let pk = PrivateKey(seed: seed)
		let newPk = try pk.derive(at: 44, hardened: true)
			.derive(at: 60, hardened: true)
			.derive(at: 0, hardened: true)
			.derive(at: 0)
			.derive(at: 0)
		return newPk
	}

    func setRandomEncryptionKeyIfNotExists() {
        if nil == self.encryptionKey() {
            self.save(password: String.random(length: 32))
        }
    }

	//save hash of password
	func save(password: String) {
		let hash = password.bytes.sha256()
		let data = Data(bytes: hash)
		self.secureStorage.set(data, forKey: self.encryptionKeyKey)
	}

	func encryptionKey() -> Data? {
		let val = secureStorage.object(forKey: encryptionKeyKey) as? Data
		return val
	}

	func save(encryptionKey: Data) {
		DispatchQueue.main.async {
			self.secureStorage.set(encryptionKey, forKey: self.encryptionKeyKey)
		}
	}

	func deleteEncryptionKey() {
		DispatchQueue.main.async {
			self.secureStorage.removeObject(forKey: self.encryptionKeyKey)
		}
	}

	//Generate Seed from mnemonic
	func seed(mnemonic: String, passphrase: String = "") -> Data? {
		if let seed = RawTransactionSigner.seed(from: mnemonic) {
			return Data(hex: seed)
		}
		return nil
	}

	//Save PK to SecureStorage

	func save(mnemonic: String, password: Data) throws {
		guard let key = self.address(from: mnemonic) else {
			return
		}

		guard let data = try? encryptedMnemonic(mnemonic: mnemonic, password: password) else {
			throw AccountManagerError.privateKeyCanNotBeSaved
		}
        secureStorage.set(data, forKey: key)
    }

      func remove(key: String) {
          secureStorage.removeObject(forKey: key)
      }

    func saveMnemonic(mnemonic: String) throws {
        guard let password = self.encryptionKey() else { throw AccountManagerError.noEncryptionKey }
        try self.save(mnemonic: mnemonic, password: password)
    }

	func encryptedMnemonic(mnemonic: String, password: Data) throws -> Data? {
		do {
			let aes = try AES(key: password.bytes, blockMode: CBC(iv: self.iv!.bytes))
			let ciphertext = try aes.encrypt(Array(mnemonic.utf8))

			guard ciphertext.count > 0 else {
				//throw error
				assert(true)
				throw AccountManagerError.privateKeyEncryptionFaulted
			}
			return Data(bytes: ciphertext)
		} catch {
			throw AccountManagerError.privateKeyUnableToEncrypt
		}
	}

	func address(from mnemonic: String) -> String? {
		guard let seed = self.seed(mnemonic: mnemonic) else {
			return nil
		}

		let pk = PrivateKey(seed: seed)

		guard
			let newPk = try? pk.derive(at: 44, hardened: true)
				.derive(at: 60, hardened: true)
				.derive(at: 0, hardened: true)
				.derive(at: 0)
				.derive(at: 0),
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		return address
	}

	// MARK: -

	func privateKey(for address: String) -> PrivateKey? {
		guard let mnemonic = self.mnemonic(for: address),
			let seed = self.seed(mnemonic: mnemonic) else {
				return nil
		}
		do {
			return try self.privateKey(from: seed)
		} catch {
			return nil
		}
	}

	func mnemonic(for address: String) -> String? {
    guard let encryptedMnemonic = secureStorage.object(forKey: address.stripMinterHexPrefix()) as? Data,
			let password = self.encryptionKey() else {
			return nil
		}
		return decryptMnemonic(encrypted: encryptedMnemonic, password: password)
	}

	func encryptedMnemonic(for address: String) -> Data? {
		return secureStorage.object(forKey: address) as? Data
	}

	func decryptMnemonic(encrypted: Data, password: Data) -> String? {
		let aes = try? AES(key: password.bytes, blockMode: CBC(iv: self.iv!.bytes))
		guard let decrypted = try? aes?.decrypt(encrypted.bytes) else {
			return nil
		}

    let mnemonic = Data(bytes: decrypted)
		return String(data: mnemonic, encoding: .utf8)
	}

	// MARK: -

	func loadLocalAccounts() -> [AccountItem]? {
		let accounts = database.objects(class: AccountDataBaseModel.self,
																		query: nil) as? [AccountDataBaseModel]

		let res = accounts?.map { (dbModel) -> AccountItem in
      return AccountItem(title: dbModel.title,
                         address: "Mx" + dbModel.address.stripMinterHexPrefix(),
                         emoji: dbModel.emoji,
                         lastSelected: Date(timeIntervalSince1970: dbModel.lastSelected))
    }.sorted(by: { (account1, account2) -> Bool in
      return account1.lastSelected > account2.lastSelected
    })
		return res
	}

	// MARK: -

	func saveLocalAccount(account: AccountItem) {
		guard let res = database.objects(class: AccountDataBaseModel.self,
																		 query: "address == \"\(account.address)\"")?.first as? AccountDataBaseModel else {
      let address = account.address.stripMinterHexPrefix().lowercased()
			let dbModel = AccountDataBaseModel()
      dbModel.id = UUID().uuidString
			dbModel.address = address
      dbModel.emoji = account.emoji
//      dbModel.title = "Mx" + TransactionTitleHelper.title(from: address)

      do {
        try database.add(object: dbModel)
      } catch {
        return
      }
			return
		}

		let addressesToUnset = database.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]

		database.update {
			res.substitute(with: account)
		}
	}
}
