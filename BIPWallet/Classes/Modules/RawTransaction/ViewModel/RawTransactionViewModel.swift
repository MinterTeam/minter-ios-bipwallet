//
//  RawTransactionViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import MinterMy
import BigInt
import RxSwift
import RxCocoa

class RawTransactionViewModel: BaseViewModel, ViewModel {// swiftlint:disable:this type_body_length cyclomatic_complexity

	// MARK: -

	enum RawTransactionViewModelError: Error {
		case authRequired
		case noPrivateKey
		case incorrectTxData
	}

	enum CellIdentifierPrefix: String {
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case button = "ButtonTableViewCell_send"
		case cancelButton = "ButtonTableViewCell_cancel"
	}

	// MARK: - ViewModelProtocol

	struct Input {
    var viewDidAppear: AnyObserver<Void>
  }

	struct Output {
		var sections: Observable<[BaseTableSectionItem]>
		var shouldClose: Observable<Void>
		var errorNotification: Observable<NotifiableError?>
		var successNotification: Observable<NotifiableSuccess?>
		var vibrate: Observable<Void>
		var popup: Observable<PopupViewController?>
		var lastTransactionExplorerURL: () -> (URL?)
    var isLoading: Observable<Bool>
    var showExchange: Observable<Void>
	}

	struct Dependency {
		var account: RawTransactionViewModelAccountProtocol
		var gate: RawTransactionViewModelGateProtocol
    var authService: AuthService
    var balanceService: BalanceService
	}

	var input: RawTransactionViewModel.Input!
	var output: RawTransactionViewModel.Output!
	var dependency: RawTransactionViewModel.Dependency!

	// MARK: -

  lazy var lastBlockString = Observable<Int>.timer(0, period: 1, scheduler: MainScheduler.instance)
    .withLatestFrom(self.dependency.balanceService.lastBlockAgo()).map {
      self.headerViewLastUpdatedTitleText(seconds: Date().timeIntervalSince1970 - ($0 ?? 0), shortened: true)
  }

  private let viewDidAppearSubject = PublishSubject<Void>()
	private let cancelButtonDidTapSubject = PublishSubject<Void>()
	private let errorNotificationSubject = PublishSubject<NotifiableError?>()
	private let successNotificationSubject = PublishSubject<NotifiableSuccess?>()
	private let proceedButtonDidTapSubject = PublishSubject<Void>()
  private let showSelectWalletSubject = PublishSubject<Void>()
	private let sendButtonDidTapSubject = PublishSubject<Void>()
	private let sectionsSubject = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
	private let sendingTxSubject = PublishSubject<Bool>()
	private let popupSubject = PublishSubject<PopupViewController?>()
	private let vibrateSubject = PublishSubject<Void>()
  private let isLoading = PublishSubject<Bool>()
  private let buttonTitle = PublishSubject<String?>()
  private let showExchange = PublishSubject<Void>()
  private let shouldShowNeededCoin = BehaviorRelay<Bool>(value: false)

	// MARK: -

  private var account: AccountItem? {
    didSet {
      if let account = account {
        try? self.dependency.balanceService.changeAddress(account.address)
      }
    }
  }
	private var nonce: BigUInt?
	private var payload: String?
	private var type: RawTransactionType
	private var gasPrice: BigUInt?
	private var gasCoin: String
	private var data: Data?
	private var userData: [String: Any]?

	private var multisendAddressCount = 0
	private var createCoinSymbolCount = 0

  private var neededCoin: String? {
    didSet {
      updateNeededCoinInfo()
    }
  }
  private var neededCoinAmount: Decimal? {
    didSet {
      updateNeededCoinInfo()
    }
  }

	private var fields: [[String: String]] = []
	private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
	private var gasObservable: Observable<String> {
		return currentGas.asObservable()
			.map({ [weak self] (obj) -> String in
				let payloadData = self?.payload?.data(using: .utf8)
				return self?.commissionText(for: obj, payloadData: payloadData) ?? ""
		})
	}
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter
	private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter
	private let noMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter

  ///Check data is used to rewrite RawTx Data
  private var checkData: Data?

	// MARK: -

	init(// swiftlint:disable:this type_body_length cyclomatic_complexity function_body_length
		dependency: Dependency,
    isLoggedIn: Bool = false,
		nonce: BigUInt?,
		gasPrice: BigUInt?,
		gasCoin: String?,
		type: RawTransactionType,
		data: Data?,
		payload: String?,
		serviceData: Data?,
		signatureType: Data?,
		userData: [String: Any]? = [:]
	) throws {

		self.dependency = dependency

		self.type = type
		self.gasPrice = gasPrice
		self.gasCoin = gasCoin ?? Coin.baseCoin().symbol!
		self.nonce = nonce
		self.userData = userData

		super.init()

		self.payload = payload
		self.data = data

		try makeFields(data: data)

    if let data = data, let txData = RLP.decode(data), let content = txData[0]?.content {
      switch content {
      case .list(let items, _, _):
        switch type {
          case .redeemCheck:
          guard let checkData = items[0].data else {
            throw RawTransactionViewModelError.incorrectTxData
          }
          self.checkData = checkData
        default:
          break
        }
      default:
        break
      }
    }

    self.input = Input(viewDidAppear: viewDidAppearSubject.asObserver())

		self.output = Output(sections: sectionsSubject.asObservable(),
												 shouldClose: cancelButtonDidTapSubject.asObservable(),
												 errorNotification: errorNotificationSubject.asObservable(),
												 successNotification: successNotificationSubject.asObservable(),
												 vibrate: vibrateSubject.asObservable(),
												 popup: popupSubject.asObservable(),
												 lastTransactionExplorerURL: self.lastTransactionExplorerURL,
                         isLoading: isLoading.asObservable(),
                         showExchange: showExchange.asObservable()
    )

		sendButtonDidTapSubject.subscribe(onNext: { [weak self] (_) in
			self?.sendTx()
		}).disposed(by: disposeBag)

		viewDidAppearSubject.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      let accs = self.dependency.authService.accounts()
      //If there are multiple accounts - show picker
      guard self.account == nil, accs.count > 1 else {
        self.account = accs.first
        return
      }

			self.vibrateSubject.onNext(())

			let viewModel = ConfirmPopupViewModel(desc: "You’re about to perform a transaction.\nChoose your active wallet.".localized(),
                                            buttonTitle: "Confirm".localized(),
                                            dependency: ConfirmPopupViewModel.Dependency(authService: self.dependency.authService))
			viewModel.buttonTitle = "Confirm".localized()
			viewModel.cancelTitle = "Cancel".localized()
			viewModel.output.didTapActionButton
        .subscribe(onNext: { [weak self] (item) in
          self?.account = item
          self?.popupSubject.onNext(nil)
        }).disposed(by: self.disposeBag)

			viewModel.output.didTapCancel
				.asDriver(onErrorJustReturn: ())
				.drive(onNext: { _ in
					self.popupSubject.onNext(nil)
				}).disposed(by: self.disposeBag)

			self.sendingTxSubject.asDriver(onErrorJustReturn: false)
				.drive(viewModel.input.activityIndicator)
				.disposed(by: self.disposeBag)

      let popup = ConfirmPopupViewController.initFromStoryboard(name: "Popup")
      popup.viewModel = viewModel
      viewModel.dismissable = false
			self.popupSubject.onNext(popup)
		}).disposed(by: disposeBag)

    proceedButtonDidTapSubject.subscribe(sendButtonDidTapSubject).disposed(by: disposeBag)

    dependency.gate.minGas().subscribe(currentGas).disposed(by: disposeBag)

    dependency.balanceService.balances().map({ (val) -> Bool in
      guard let neededCoin = self.neededCoin, let neededAmount = self.neededCoinAmount else { return false }
      return (val.balances[neededCoin]?.0 ?? 0.0) < neededAmount
    }).subscribe(onNext: { val in
      self.shouldShowNeededCoin.accept(val)
    }).disposed(by: disposeBag)

    shouldShowNeededCoin.debounce(.seconds(1), scheduler: MainScheduler.instance).subscribe(onNext: { (val) in
      self.sectionsSubject.onNext(self.createSections())
    }).disposed(by: disposeBag)

		sectionsSubject.onNext(createSections())
	}

  func address() throws -> String {
    guard let adr = self.account?.address else {
      throw RawTransactionViewModelError.noPrivateKey
    }
    return adr
  }

//  func shouldShowNeededCoin() -> Bool {
//    let hasNeededCoin = self.neededCoinAmount != nil && self.neededCoin != nil
////    return self.dependency.balanceService.balances()
//    return hasNeededCoin
//  }

  func updateNeededCoinInfo() {
    guard let neededAmount = self.neededCoinAmount, let neededCoin = self.neededCoin else {
      return
    }

    print("showing")
  }

	private func sendTx() {
    guard let address = self.account?.address.stripMinterHexPrefix() else {
			return
		}

		Observable.combineLatest(self.dependency.gate.nonce(address: "Mx" + address),
														 self.dependency.gate.minGas())
			.do(onSubscribe: { [weak self] in
				self?.sendingTxSubject.onNext(true)
        self?.isLoading.onNext(true)
			}).flatMap({ [weak self] (result) -> Observable<String?> in
				let (nonce, _) = result
				guard let nnnc = BigUInt(decimal: Decimal(nonce+1)),
					let gasCoin = self?.gasCoin,
					let type = self?.type,
          let privateKey = try self?.dependency.account.privatekey(for: address)
					else {
						return Observable.error(RawTransactionViewModelError.noPrivateKey)
				}

				let gasPrice = (self?.gasPrice != nil) ? self!.gasPrice! : BigUInt(try self?.currentGas.value() ?? RawTransactionDefaultGasPrice)
				let resultNonce = (self?.nonce != nil) ? self!.nonce! : nnnc

        if let passwordString = self?.userData?["p"] as? String,
          let proof = RawTransactionSigner.proof(address: address, passphrase: passwordString),
          let checkData = self?.checkData {
            self?.data = MinterCore.RedeemCheckRawTransactionData(rawCheck: checkData, proof: proof).encode()
        }

				let tx = RawTransaction(nonce: resultNonce,
																gasPrice: gasPrice,
																gasCoin: gasCoin,
																type: BigUInt(type.rawValue),
																data: self?.data ?? Data(),
																payload: self?.payload?.data(using: .utf8) ?? Data())

				let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: privateKey)
        return self?.dependency.gate.send(rawTx: signedTx).map {$0.0} ?? Observable<String?>.empty()
			}).subscribe(onNext: { [weak self] (result) in
        self?.isLoading.onNext(false)
				self?.lastSentTransactionHash = result
				if let sentViewModel = self?.sentViewModel() {
          let sentViewController = SentPopupViewController.initFromStoryboard(name: "Popup")
          sentViewController.viewModel = sentViewModel
					self?.popupSubject.onNext(sentViewController)
				}

				self?.sendingTxSubject.onNext(false)
			}, onError: { [weak self] (error) in
        self?.isLoading.onNext(false)
				self?.sendingTxSubject.onNext(false)
				self?.handle(error: error)
				self?.popupSubject.onNext(nil)
			}).disposed(by: disposeBag)
	}

	// MARK: - Sections

	private func createSections() -> [BaseTableSectionItem] {
		var items = [RawTransactionFieldTableViewCellItem]()
    for elem in fields.enumerated() {
      let field = elem.element

      var item: RawTransactionFieldTableViewCellItem
      if elem.offset == 0 {
        item = RawTransactionFieldWithBlockTimeTableViewCellItem(reuseIdentifier: "RawTransactionFieldWithBlockTimeTableViewCell",
                                                                 identifier: "RawTransactionFieldTableViewCell_" + (field["key"] ?? String.random()))
        (item as? RawTransactionFieldWithBlockTimeTableViewCellItem)?.lastBlockText = self.lastBlockString
      } else {
        item = RawTransactionFieldTableViewCellItem(reuseIdentifier: "RawTransactionFieldTableViewCell",
                                                    identifier: "RawTransactionFieldTableViewCell_" + (field["key"] ?? String.random()))
      }
			item.title = field["key"]
			item.value = field["value"]
			items.append(item)
		}

		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																				identifier: CellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		let payloadData = payload?.data(using: .utf8)
		fee.subtitle = self.commissionText(for: 1, payloadData: payloadData)
		fee.subtitleObservable = self.gasObservable

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: CellIdentifierPrefix.blank.rawValue)
    let blank0 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: CellIdentifierPrefix.blank.rawValue + "_0")
    blank0.height = 16.0

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: CellIdentifierPrefix.button.rawValue)
		button.title = "Confirm and Send".localized()
		button.buttonPattern = "filled"
    button.buttonColor = "purple"
    button.isLoadingObserver = isLoading
    button.isButtonEnabledObservable = isLoading.map { !$0 }
    button.buttonTitleObservable = isLoading.map { $0 ? "" : "Confirm and Send" }

		button.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(proceedButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)

		let cancelButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																							 identifier: CellIdentifierPrefix.cancelButton.rawValue)
		cancelButton.title = "Cancel".localized()
		cancelButton.buttonPattern = "blank_black"
		cancelButton.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(cancelButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)

		let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																				identifier: CellIdentifierPrefix.blank.rawValue + "_2")
		let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																				identifier: CellIdentifierPrefix.blank.rawValue + "_3")

    var section = BaseTableSectionItem(identifier: "RawTransactionSections", header: "")
		section.items = items + [blank0, fee, blank, blank2, blank3]

    if shouldShowNeededCoin.value {
      let exchangeCoins = RawTransactionConvertCoinCellItem(reuseIdentifier: "RawTransactionConvertCoinCell",
                                                            identifier: "RawTransactionConvertCoinCell")

      exchangeCoins.exchange.subscribe(showExchange).disposed(by: disposeBag)
      exchangeCoins.title = dependency.balanceService.balances().map({ (val) -> String in
        guard let neededCoin = self.neededCoin, let neededAmount = self.neededCoinAmount else { return "" }

        let amount = CurrencyNumberFormatter.formattedDecimal(with: neededAmount,
                                                              formatter: self.coinFormatter)
        let additionalAmount = max(0.0, neededAmount - (val.balances[neededCoin]?.0 ?? 0.0))
        return "Not enough coins. Please buy \(additionalAmount) \(neededCoin) to finish transaction."
      })

      section.items += [exchangeCoins]
    }

    section.items += [button, cancelButton]
		return [section]
	}

	func sentViewModel() -> SentPopupViewModel {
    let contacts = LocalStorageContactsService()
    let recipientInfo = ExplorerRecipientInfoService(contactsService: contacts)
    let vm = SentPopupViewModel(dependency: SentPopupViewModel.Dependency(recipientInfoService: recipientInfo))
		vm.actionButtonTitle = "View Transaction".localized()
		vm.secondButtonTitle = "Close".localized()
		vm.title = "Success!".localized()
		vm.noAvatar = true
		vm.desc = "Transaction sent!"
		return vm
	}

	private func commissionText(for gas: Int, payloadData: Data? = nil) -> String {
    if self.type == .redeemCheck {
      return "0.0000 " + (Coin.baseCoin().symbol ?? "")
    }
		let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
		let commission = (self.type
			.commission(options: [.multisendCount: self.multisendAddressCount,
														.coinSymbolLettersCount: self.createCoinSymbolCount]) + payloadCom)
			.PIPToDecimal() * Decimal(gas)
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: commission,
																																 formatter: coinFormatter)
		return balanceString + " " + (Coin.baseCoin().symbol ?? "")
	}

	private func handle(error: Error) {
		var notification: NotifiableError
		if let error = error as? HTTPClientError {
			if let errorMessage = error.userData?["log"] as? String {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: errorMessage)
			} else {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: "Unable to send transaction".localized())
			}
		} else if let error = error as? RawTransactionViewModelError, error == .noPrivateKey {
			notification = NotifiableError(title: "No private key found".localized())
		} else {
			notification = NotifiableError(title: "An Error Occurred".localized(),
																		 text: "Unable to send transaction".localized())
		}
		self.errorNotificationSubject.onNext(notification)
	}

	var lastSentTransactionHash: String?
	func lastTransactionExplorerURL() -> URL? {
		guard nil != lastSentTransactionHash else {
			return nil
		}
		return URL(string: MinterExplorerBaseURL! + "/transactions/" + (lastSentTransactionHash ?? ""))
	}
}

extension RawTransactionViewModel {

	func makeFields(data: Data?) throws { // swiftlint:disable:this type_body_length cyclomatic_complexity function_body_length
		if
			let data = data,
			let txData = RLP.decode(data),
			let content = txData[0]?.content {
        switch content {
        case .list(let items, _, _):
          switch type {

          case .sendCoin:
            guard let coinData = items[0].data,
              let coin = String(coinData: coinData),
              let addressData = items[1].data,
              let valueData = items[2].data,
              addressData.toHexString().isValidAddress() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let value = BigUInt(valueData)
            let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                        formatter: decimalFormatter)

            self.neededCoin = coin
            self.neededCoinAmount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()

            let sendingValue = amountString + " " + coin
            fields.append(["key": "You are Sending".localized(), "value": sendingValue])
            fields.append(["key": "To".localized(), "value": "Mx" + addressData.toHexString()])

          case .sellCoin:
            fields.append(["key": "Type".localized(), "value": "Sell Coin"])
            guard
              let coinFromData = items[0].data,
              let coinFrom = String(coinData: coinFromData),
              let valueData = items[1].data,
              let coinToData = items[2].data,
              let coinTo = String(coinData: coinToData),
              let minimumValueToBuyData = items[3].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let minimumValueToBuy = BigUInt(minimumValueToBuyData)
            let value = BigUInt(valueData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter)

            let minimumValueToBuyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: minimumValueToBuy) ?? 0).PIPToDecimal(),
                                                                                   formatter: coinFormatter)

            self.neededCoin = coinFrom
            self.neededCoinAmount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()

            fields.append(["key": "Coin From".localized(), "value": coinFrom])
            fields.append(["key": "Amount".localized(), "value": amountString])
            fields.append(["key": "Coin To".localized(), "value": coinTo])
            fields.append(["key": "Minimum Value To Buy", "value": minimumValueToBuyString])

          case .sellAllCoins:
            fields.append(["key": "Type".localized(), "value": "Sell All"])
            guard let coinFromData = items[0].data,
              let coinFrom = String(coinData: coinFromData),
              let coinToData = items[1].data,
              let coinTo = String(coinData: coinToData),
              let minimumValueToBuyData = items[2].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }

            let minimumValueToBuy = BigUInt(minimumValueToBuyData)
            let minimumValueToBuyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: minimumValueToBuy) ?? 0).PIPToDecimal(),
                                                                                   formatter: decimalFormatter)

            fields.append(["key": "Coin From".localized(), "value": coinFrom])
            fields.append(["key": "Coin To".localized(), "value": coinTo])
            fields.append(["key": "Minimum Value To Buy", "value": minimumValueToBuyString])

          case .buyCoin:
            fields.append(["key": "Type".localized(), "value": "Buy Coin"])
            guard let coinFromData = items[0].data,
              let coinFrom = String(coinData: coinFromData),
              let valueData = items[1].data,
              let coinToData = items[2].data,
              let coinTo = String(coinData: coinToData),
              let maximumValueToSpendData = items[3].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let maximumValueToSpend = BigUInt(maximumValueToSpendData)
            let value = BigUInt(valueData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
                                                                        formatter: coinFormatter)

            let maximumValueToSpendString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: maximumValueToSpend) ?? 0).PIPToDecimal(),
                                                                                   formatter: coinFormatter)
            fields.append(["key": "Coin From".localized(), "value": coinFrom])
            fields.append(["key": "Amount".localized(), "value": amountString])
            fields.append(["key": "Coin To".localized(), "value": coinTo])
            fields.append(["key": "Maximum Value To Spend".localized(), "value": maximumValueToSpendString])

          case .createCoin:
            fields.append(["key": "Type".localized(), "value": "Create Coin"])
            guard let coinNameData = items[0].data,
              let coinName = String(data: coinNameData, encoding: .utf8),
              let coinSymbolData = items[1].data,
              let coinSymbol = String(coinData: coinSymbolData),
              let initialAmountData = items[2].data,
              let initialReserveData = items[3].data,
              let constantReserveRatioData = items[4].data,
              coinSymbol.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            self.createCoinSymbolCount = coinSymbol.count
            let initialAmount = BigUInt(initialAmountData)
            let initialReserve = BigUInt(initialReserveData)
            let crr = BigUInt(constantReserveRatioData)
            let initialAmountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialAmount) ?? 0).PIPToDecimal(),
                                                                               formatter: coinFormatter)
            let initialReserveString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialReserve) ?? 0).PIPToDecimal(),
                                                                                formatter: coinFormatter)
            let crrString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: crr) ?? 0),
                                                                     formatter: noMantissaFormatter)
            fields.append(["key": "Coin Name".localized(), "value": coinName])
            fields.append(["key": "Coin Symbol".localized(), "value": coinSymbol])
            fields.append(["key": "Initial Amount".localized(), "value": initialAmountString])
            fields.append(["key": "Initial Reserve".localized(), "value": initialReserveString])
            fields.append(["key": "Constant Reserve Ration".localized(), "value": crrString])
            if let maxSupplyData = items[safe: 5]?.data {
              let maxSupply = BigUInt(maxSupplyData)
              let maxSupplyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: maxSupply) ?? 0).PIPToDecimal(),
                                                                             formatter: coinFormatter)
              fields.append(["key": "Max Supply".localized(), "value": BigUInt.compare(maxSupply, BigUInt(decimal: Decimal(pow(10.0, 18.0+15.0)))!) == .orderedSame ? "10¹⁵ (max)" : maxSupplyString])
            } else {
              fields.append(["key": "Max Supply".localized(), "value": "10¹⁵ (max)"])
            }

          case .declareCandidacy:
            fields.append(["key": "Type".localized(), "value": "DECLARE CANDIDACY".localized()])
            guard
              let addressData = items[0].data,
              let publicKeyData = items[1].data,
              let commissionData = items[2].data,
              let coinData = items[3].data,
              let coin = String(coinData: coinData),
              let stakeData = items[4].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let commission = BigUInt(commissionData)
            let commissionString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: commission) ?? 0),
                                                                            formatter: noMantissaFormatter)

            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: coinFormatter)
            fields.append(["key": "Address".localized(), "value": "Mx" + addressData.toHexString()])
            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])
            fields.append(["key": "Commission".localized(), "value": commissionString])
            fields.append(["key": "Coin".localized(), "value": coin])
            fields.append(["key": "Stake".localized(), "value": amountString])

          case .delegate:
            fields.append(["key": "Type".localized(), "value": "Delegate".localized()])
            guard
              let publicKeyData = items[0].data,
              let coinData = items[1].data,
              let coin = String(coinData: coinData),
              let stakeData = items[2].data,
              coin.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: coinFormatter)

            self.neededCoin = coin
            self.neededCoinAmount = (Decimal(bigInt: stake) ?? 0).PIPToDecimal()

            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])
            fields.append(["key": "Coin".localized(), "value": coin])
            fields.append(["key": "Amount".localized(), "value": amountString])

          case .unbond:
            fields.append(["key": "Type".localized(), "value": "Unbond".localized()])
            guard
              let publicKeyData = items[0].data,
              let coinData = items[1].data,
              let coin = String(coinData: coinData),
              let stakeData = items[2].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: coinFormatter)
            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])
            fields.append(["key": "Coin".localized(), "value": coin])
            fields.append(["key": "Amount".localized(), "value": amountString])

          case .redeemCheck:
            fields.append(["key": "Type".localized(), "value": "Redeem Check".localized()])
            guard
              let checkData = items[0].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            if let checkPayload = RLP.decode(checkData)?[0]?.content {
              switch checkPayload {
              case .list(let checkPayloadItems, _, _):
                if
                  let checkCoinData = checkPayloadItems[safe: 3]?.data,
                  let checkAmount = checkPayloadItems[safe: 4]?.data {
                  let value = BigUInt(checkAmount)
                  let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
                  let amountString = decimalFormatter.formattedDecimal(with: amount)
                  let checkValue = amountString + " " + (String(coinData: checkCoinData) ?? "")
                  fields.append(["key": "Amount".localized(), "value": checkValue])
                }
              case .noItem:
                break
              case .data(_):
                break
              }
            }

            fields.append(["key": "Check".localized(), "value": "Mc" + checkData.toHexString()])
            if let passwordString = userData?["p"] as? String {
              fields.append(["key": "Password".localized(), "value": passwordString])
            } else if let proofData = items[1].data, proofData.count > 0 {
              fields.append(["key": "Proof".localized(), "value": proofData.toHexString()])
            } else {
              throw RawTransactionViewModelError.incorrectTxData
            }

          case .setCandidateOnline:
            fields.append(["key": "Type".localized(), "value": "Set Candidate On".localized()])
            guard let publicKeyData = items[0].data else {
              throw RawTransactionViewModelError.incorrectTxData
            }
            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])

          case .setCandidateOffline:
            fields.append(["key": "Type".localized(), "value": "Set Candidate Off".localized()])
            guard let publicKeyData = items[0].data else {
              throw RawTransactionViewModelError.incorrectTxData
            }
            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])

          case .createMultisigAddress:
            fields.append(["key": "Type".localized(), "value": "Create Multisig Address".localized()])
            guard
              let thresholdData = items[0].data,
              let weightData = items[1].data,
              let weightArray = RLP.decode(weightData),
              let addressData = items[2].data,
              let addressArray = RLP.decode(addressData)
            else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            for idx in 0..<(weightArray.count ?? 0) {
              let address = "Mx" + (addressArray[idx]?.data?.toHexString() ?? "")

              let weight = BigUInt(weightArray[idx]?.data ?? Data())
              let weightString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: weight) ?? 0),
                                                                          formatter: noMantissaFormatter)
              fields.append(["key": "Address : Weight".localized(),
                             "value": TransactionTitleHelper.title(from: address) + " : " + weightString])
            }
            let threshold = BigUInt(thresholdData)
            let thresholdString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: threshold) ?? 0),
                                                                           formatter: noMantissaFormatter)
            fields.append(["key": "Threshold".localized(), "value": thresholdString])

          case .multisend:
            guard
              let arrayData = items[0].data,
              let array = RLP.decode(arrayData) else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            multisendAddressCount = array.count ?? 0
            for idx in 0..<(array.count ?? 0) {
              if
                let addressDictData = array[idx]?.data,
                let addressDict = RLP.decode(addressDictData),
                let coinData = addressDict[0]?.data,
                  let coin = String(coinData: coinData),
                  let addressData = addressDict[1]?.data,
                  let valueData = addressDict[2]?.data {
                    let address = addressData.toHexString()
                    let value = BigUInt(valueData)
                    let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
                    let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                                formatter: coinFormatter)
                    let sendingValue = amountString + " " + coin
                    fields.append(["key": "You are Sending".localized(), "value": sendingValue])
                    fields.append(["key": "To".localized(), "value": "Mx" + address])
                }
            }

          case .editCandidate:
            fields.append(["key": "Type".localized(), "value": "Edit Candidate".localized()])
            guard let publicKeyData = items[0].data,
              let rewardAddressData = items[1].data,
              let ownerAddressData = items[2].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            fields.append(["key": "Public Key".localized(), "value": "Mp" + publicKeyData.toHexString()])
            fields.append(["key": "Reward Address".localized(), "value": "Mx" + rewardAddressData.toHexString()])
            fields.append(["key": "Owner Address".localized(), "value": "Mx" + ownerAddressData.toHexString()])
          }
          break

        case .noItem: break
        case .data(_): break
        }
        if gasCoin.isValidCoin() {
          fields.append(["key": "Gas Coin".localized(), "value": gasCoin])
        }
        if let payload = payload, payload.count > 0 {
          fields.append(["key": "Payload Message".localized(), "value": payload])
        }
      }
	}
}

extension RawTransactionViewModel: LastBlockViewable {}
