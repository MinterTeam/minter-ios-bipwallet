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

  //(Coin Name, Amount to buy, Total amount needed for tx)
  typealias NeededCoinAndAmount = (String, Decimal, Decimal)

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
    var didTapEditing: AnyObserver<Void>
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
    var showExchange: Observable<NeededCoinAndAmount?>
    var isButtonEnabled: Observable<Bool>
    var isEditButtonHidden: Observable<Bool>
	}

	struct Dependency {
		var account: RawTransactionViewModelAccountProtocol
		var gate: RawTransactionViewModelGateProtocol
    var authService: AuthService
    var balanceService: BalanceService
    var coinService: CoinService
	}

	var input: RawTransactionViewModel.Input!
	var output: RawTransactionViewModel.Output!
	var dependency: RawTransactionViewModel.Dependency!

  struct Field {
    var key: String?
    var value: String? {
      didSet {
        onChanged?()
      }
    }
    var isEditable: Bool = false
    var validateWithError: ((String?) -> (String?))?
    var modify: ((String?) -> (String?))?
    var keyboardType: UIKeyboardType?
    var onChanged: (() -> ())?
  }

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
  private let isLoading = BehaviorSubject<Bool>(value: false)
  private let buttonTitle = PublishSubject<String?>()
  private let showExchange = PublishSubject<NeededCoinAndAmount?>()
  private let shouldShowNeededCoin = BehaviorRelay<Bool>(value: false)
  private let didTapEdit = PublishSubject<Void>()
  private let isEditing = BehaviorRelay<Bool>(value: false)
  private let isButtonEnabled = BehaviorRelay<Bool>(value: true)

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
  private var gasCoin: String = Coin.baseCoin().symbol!
  private var gasCoinId: BigUInt
  private var data: Data? {
    didSet {
      self.isButtonEnabled.accept(data != nil)
    }
  }
	private var userData: [String: Any]?

	private var multisendAddressCount = 0
	private var createCoinSymbolCount = 0

  private var neededCoin: String?
  private var neededCoinAmount: Decimal?

	private var fields: [Field] = []
	private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
  private let commissionTextForceUpdate = PublishSubject<Void>()
	private var commissionTextObservable: Observable<String> {
    return Observable.of(commissionTextForceUpdate, sectionsSubject.map{_ in}, currentGas.map{_ in}).merge().withLatestFrom(currentGas)
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
		gasCoinId: BigUInt?,
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
		self.gasCoinId = gasCoinId ?? BigUInt(Coin.baseCoin().id!)
		self.nonce = nonce
		self.userData = userData

		super.init()

		self.payload = payload
		self.data = data

//		try makeFields(data: data)

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

    self.input = Input(viewDidAppear: viewDidAppearSubject.asObserver(),
                       didTapEditing: didTapEdit.asObserver()
    )

		self.output = Output(sections: sectionsSubject.asObservable(),
												 shouldClose: cancelButtonDidTapSubject.asObservable(),
												 errorNotification: errorNotificationSubject.asObservable(),
												 successNotification: successNotificationSubject.asObservable(),
												 vibrate: vibrateSubject.asObservable(),
												 popup: popupSubject.asObservable(),
												 lastTransactionExplorerURL: self.lastTransactionExplorerURL,
                         isLoading: isLoading.asObservable(),
                         showExchange: showExchange.asObservable(),
                         isButtonEnabled: isButtonEnabled.asObservable(),
                         isEditButtonHidden: Observable.of({
                          switch type {
                          case .sendCoin, .sellCoin, .sellAllCoins, .buyCoin, .delegate, .unbond:
                            return false
                          default:
                            return true
                          }
                         }())
    )

    sendButtonDidTapSubject.flatMap { _ in self.dependency.coinService.updateCoinsWithResponse() }.subscribe(onNext: { [weak self] (_) in
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
                                            buttonTitle: "Continue".localized(),
                                            dependency: ConfirmPopupViewModel.Dependency(authService: self.dependency.authService))
      viewModel.buttonTitle = "Continue".localized()
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
      viewModel.dismissable = true
      self.popupSubject.onNext(popup)
    }).disposed(by: disposeBag)

    proceedButtonDidTapSubject.subscribe(sendButtonDidTapSubject).disposed(by: disposeBag)

    dependency.gate.minGas().subscribe(currentGas).disposed(by: disposeBag)

    Observable.of(isEditing.map {_ in}, dependency.balanceService.balances().map {_ in}).merge()
      .debounce(.microseconds(100), scheduler: MainScheduler.instance)
      .withLatestFrom(dependency.balanceService.balances()).map({ [unowned self] (val) -> Bool in
        guard let neededCoin = self.neededCoin, let neededAmount = self.neededCoinAmount else { return false }
        return (val.balances[neededCoin]?.0 ?? 0.0) < neededAmount
      }).subscribe(onNext: { val in
        self.shouldShowNeededCoin.accept(val)
      }).disposed(by: disposeBag)

    shouldShowNeededCoin.debounce(.seconds(1), scheduler: MainScheduler.instance).subscribe(onNext: { [unowned self] (val) in
      self.sectionsSubject.onNext(self.createSections())
    }).disposed(by: disposeBag)

    didTapEdit.withLatestFrom(isEditing).map({ (val) -> Bool in
      return !val
    }).subscribe(onNext: { [weak self] val in
      guard let `self` = self else { return }

      if self.data == nil { return }

      self.isEditing.accept(val)

      self.fields = []
      try? self.makeFields(data: self.data)
      self.sectionsSubject.onNext(self.createSections())
    }).disposed(by: disposeBag)

    self.dependency.coinService.coins().do(afterNext: { [unowned self] (coins) in
      self.fields = []
      try? self.makeFields(data: data)
      self.sectionsSubject.onNext(self.createSections())
    }).subscribe().disposed(by: disposeBag)
	}

  func address() throws -> String {
    guard let adr = self.account?.address else {
      throw RawTransactionViewModelError.noPrivateKey
    }
    return adr
  }

  private func sendTx() {
    guard let address = self.account?.address.stripMinterHexPrefix() else {
      return
    }

    Observable.combineLatest(self.dependency.gate.nonce(address: "Mx" + address),
                             self.dependency.gate.minGas()).take(1)
      .do(onSubscribe: { [weak self] in
        self?.sendingTxSubject.onNext(true)
        self?.isLoading.onNext(true)
      }).flatMap({ [weak self] (result) -> Observable<String?> in
        let (nonce, _) = result
        guard let nnnc = BigUInt(decimal: Decimal(nonce+1)),
              let gasCoin = self?.dependency.coinService.coinId(symbol: self?.gasCoin ?? ""),
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
                                gasCoinId: gasCoin,
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
    var items = [BaseCellItem]()
    for elem in fields.enumerated() {
      let field = elem.element
      var item: BaseCellItem
      if elem.offset == 0 {
        if isEditing.value {
          guard field.isEditable else { continue }
          item = RawTransactionTextViewCellItem(reuseIdentifier: "RawTransactionTextViewCell",
                                                identifier: "RawTransactionTextViewCell_" + (field.key ?? String.random()))
          (item as? RawTransactionTextViewCellItem)?.title = field.key ?? ""
          (item as? RawTransactionTextViewCellItem)?.value = field.value
          (item as? RawTransactionTextViewCellItem)?.lastBlockText = self.lastBlockString
          (item as? RawTransactionTextViewCellItem)?.text.distinctUntilChanged()
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .filter { $0 != nil }
            .map({ (val) -> String? in
              return field.modify?(val) ?? val
            }).subscribe(onNext: { val in
              (item as? RawTransactionTextViewCellItem)?.text.accept(val)
              if let error = field.validateWithError?(val) {
                (item as? RawTransactionTextViewCellItem)?.state.onNext(.invalid(error: error))
              } else {
                (item as? RawTransactionTextViewCellItem)?.state.onNext(.default)
              }
            }).disposed(by: disposeBag)
          (item as? RawTransactionTextViewCellItem)?.keybordType = field.keyboardType
        } else {
          item = RawTransactionFieldWithBlockTimeTableViewCellItem(reuseIdentifier: "RawTransactionFieldWithBlockTimeTableViewCell",
                                                                   identifier: "RawTransactionFieldTableViewCell_" + (field.key ?? String.random()))
          (item as? RawTransactionFieldWithBlockTimeTableViewCellItem)?.lastBlockText = self.lastBlockString
          (item as? RawTransactionFieldTableViewCellItem)?.title = field.key
          (item as? RawTransactionFieldTableViewCellItem)?.value = field.value
        }
      } else {
        if isEditing.value {
          guard field.isEditable else { continue }
          item = RawTransactionTextViewCellItem(reuseIdentifier: "RawTransactionTextViewCell",
                                                identifier: "RawTransactionTextViewCell_\(elem.offset)" + (field.key ?? String.random()))
          (item as? RawTransactionTextViewCellItem)?.title = field.key ?? ""
          (item as? RawTransactionTextViewCellItem)?.value = field.value
          (item as? RawTransactionTextViewCellItem)?.lastBlockText = Observable.just(NSAttributedString())
          (item as? RawTransactionTextViewCellItem)?.text.distinctUntilChanged()
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .filter { $0 != nil }
            .map({ (val) -> String? in
              return field.modify?(val) ?? val
            }).subscribe(onNext: { val in
              (item as? RawTransactionTextViewCellItem)?.text.accept(val)
              if let error = field.validateWithError?(val) {
                (item as? RawTransactionTextViewCellItem)?.state.onNext(.invalid(error: error))
              } else {
                (item as? RawTransactionTextViewCellItem)?.state.onNext(.default)
              }
            }).disposed(by: disposeBag)
          (item as? RawTransactionTextViewCellItem)?.keybordType = field.keyboardType
        } else {
          item = RawTransactionFieldTableViewCellItem(reuseIdentifier: "RawTransactionFieldTableViewCell",
                                                      identifier: "RawTransactionFieldTableViewCell_\(elem.offset)" + (field.key ?? String.random()))
          (item as? RawTransactionFieldTableViewCellItem)?.title = field.key
          (item as? RawTransactionFieldTableViewCellItem)?.value = field.value
        }
      }

			items.append(item)
		}

    let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
                                        identifier: CellIdentifierPrefix.fee.rawValue)
    fee.title = "Transaction Fee".localized()
    let payloadData = payload?.data(using: .utf8)
    fee.subtitle = self.commissionText(for: 1, payloadData: payloadData)
    fee.subtitleObservable = self.commissionTextObservable

    let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                       identifier: CellIdentifierPrefix.blank.rawValue)
    let blank0 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: CellIdentifierPrefix.blank.rawValue + "_0")
    blank0.height = 16.0

    let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                         identifier: CellIdentifierPrefix.button.rawValue)
    button.title = "Confirm and Send".localized()
    button.buttonPattern = "purple"
    button.buttonColor = "purple"
    button.isLoadingObserver = isLoading
    button.isButtonEnabled = true
    button.isButtonEnabledObservable = Observable.combineLatest(self.isButtonEnabled, isLoading).map {
      return $0 && !$1
    }
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
    blank3.height = 3

    var section = BaseTableSectionItem(identifier: "RawTransactionSections", header: "")
		section.items = items + [blank0, fee, blank, blank2, blank3]

    if shouldShowNeededCoin.value && !isEditing.value {
      let exchangeCoins = RawTransactionConvertCoinCellItem(reuseIdentifier: "RawTransactionConvertCoinCell",
                                                            identifier: "RawTransactionConvertCoinCell")

      exchangeCoins.exchange.withLatestFrom(dependency.balanceService.balances()).map({ balances in
        guard let coin = self.neededCoin, let amount = self.neededCoinAmount else {
          return nil
        }
        let newAmount = max(0.0, amount - (balances.balances[coin]?.0 ?? 0.0))
        return (coin, newAmount, self.neededCoinAmount ?? 0.0)
      }).subscribe(showExchange).disposed(by: disposeBag)
      exchangeCoins.title = dependency.balanceService.balances().map({ (val) -> String in
        guard let neededCoin = self.neededCoin, let neededAmount = self.neededCoinAmount else { return "" }

        let additionalAmount = max(0.0, neededAmount - (val.balances[neededCoin]?.0 ?? 0.0))
        let totalAmount = CurrencyNumberFormatter.formattedDecimal(with: additionalAmount,
                                                                   formatter: self.decimalFormatter,
                                                                   maxPlaces: 18)
        return "Not enough coins. Please buy \(totalAmount) \(neededCoin) to finish transaction."
      })
      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: CellIdentifierPrefix.blank.rawValue + "_4")
      blank4.height = 8

      section.items += [exchangeCoins, blank4]
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
		if let data = data, let txData = RLP.decode(data), let content = txData[0]?.content {

      var payloadField = Field(key: "Payload Message".localized(), value: payload ?? "", isEditable: true)
      payloadField.modify = { val in
        var value = val
        while value?.data(using: .utf8)?.count ?? 0 > RawTransaction.maxPayloadSize {
          value?.removeLast()
        }
        payloadField.value = value
        return value
      }

      payloadField.onChanged = { [weak self] in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {

          self?.payload = payloadField.value
          self?.commissionTextForceUpdate.onNext(())
        }
        self?.commissionTextForceUpdate.onNext(())
      }
      payloadField.validateWithError = { val in
        return (val?.data(using: .utf8) ?? Data()).count > RawTransaction.maxPayloadSize ? "Too Many Symbols".localized() : nil
      }

        switch content {
        case .list(let items, _, _):
          switch type {

          case .sendCoin:
            guard let coinData = items[0].data,
                  let coin = self.coinBy(coinIdData: coinData)?.symbol,
                  let addressData = items[1].data,
                  let valueData = items[2].data,
                  addressData.toHexString().isValidAddress() else {
                throw RawTransactionViewModelError.incorrectTxData
            }

            let value = BigUInt(valueData)
            let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                        formatter: decimalFormatter,
                                                                        maxPlaces: 18
                                                                        )

            self.neededCoin = coin
            self.neededCoinAmount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()

            var field1 = Field(key: "You are Sending".localized(), value: amountString, isEditable: true)
            field1.keyboardType = .decimalPad
            var coinField = Field(key: "Coin".localized(), value: coin, isEditable: true)
            var field3 = Field(key: "To".localized(), value: "Mx" + addressData.toHexString(), isEditable: true)

            func makeSendCoinTransactionData() {
              guard
                let address = field3.value,
                address.isValidAddress(),
                let coin = coinField.value,
                coin.isValidCoin(),
                let coinId = self.dependency.coinService.coinId(symbol: coin),
                let amount = field1.value,
                let decimalAmount = Decimal(str: amount),
                let value = BigUInt(decimal: decimalAmount.decimalFromPIP()) else {
                self.data = nil
                return
              }
              let sendData = MinterCore.SendCoinRawTransactionData(to: address, value: value, coinId: coinId)
              self.payload = payloadField.value
              self.data = sendData.encode()
            }

            //Amount
            field1.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              field1.value = retValue
              return retValue
            }
            field1.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            field1.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSendCoinTransactionData()
              }
            }

            coinField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinField.value = retValue
              return retValue
            }
            coinField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            coinField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSendCoinTransactionData()
              }
            }

            field3.modify = { val in
              let retValue = val?.replacingOccurrences(of: " ", with: "")
              field3.value = retValue
              return retValue
            }
            field3.validateWithError = { val in
              return (val?.count == 0 || val?.isValidAddress() ?? false) ? nil : "Invalid address".localized()
            }
            field3.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSendCoinTransactionData()
              }
            }

            fields.append(contentsOf: [field1, coinField, field3])

          case .sellCoin:
            let typeField = Field(key: "Type".localized(), value: "Sell Coin".localized(), isEditable: false)
            fields.append(typeField)
            guard
              let coinFromData = items[0].data,
              let coinFrom = self.coinBy(coinIdData: coinFromData)?.symbol,
              let valueData = items[1].data,
              let coinToData = items[2].data,
              let coinTo = self.coinBy(coinIdData: coinToData)?.symbol,
              let minimumValueToBuyData = items[3].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let minimumValueToBuy = BigUInt(minimumValueToBuyData)
            let value = BigUInt(valueData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter,
                                                                        maxPlaces: 18)

            let minimumValueToBuyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: minimumValueToBuy) ?? 0).PIPToDecimal(),
                                                                                   formatter: decimalFormatter,
                                                                                   maxPlaces: 18)

            self.neededCoin = coinFrom
            self.neededCoinAmount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()

            var coinFromField = Field(key: "Coin From".localized(), value: coinFrom, isEditable: true)
            coinFromField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinFromField.value = retValue
              return retValue
            }
            coinFromField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            fields.append(coinFromField)

            var coinToField = Field(key: "Coin To".localized(), value: coinTo, isEditable: true)
            coinToField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinToField.value = retValue
              return retValue
            }
            coinToField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            fields.append(coinToField)

            var amountField = Field(key: "Amount".localized(), value: amountString, isEditable: true)
            amountField.keyboardType = .decimalPad

            var minimumValueToBuyField = Field(key: "Minimum Value To Buy".localized(), value: minimumValueToBuyString, isEditable: true)
            minimumValueToBuyField.keyboardType = .decimalPad

            func makeSellCoinTransactionData() {
              guard
                let coinFrom = coinFromField.value, coinFrom.isValidCoin(),
                let coinFromId = self.dependency.coinService.coinId(symbol: coinFrom),
                let coinTo = coinToField.value, coinTo.isValidCoin(),
                let coinToId = self.dependency.coinService.coinId(symbol: coinTo),
                let amount = amountField.value, let decimalAmount = Decimal(str: amount),
                let value = BigUInt(decimal: decimalAmount.decimalFromPIP()),
                let minimumValueToBuy = minimumValueToBuyField.value, let minimumValueToBuyAmount = Decimal(str: minimumValueToBuy),
                let minimumValueToBuyValue = BigUInt(decimal: minimumValueToBuyAmount.decimalFromPIP())
              else {
                self.data = nil
                return
              }

              let data = SellCoinRawTransactionData(coinFromId: coinFromId,
                                                    coinToId: coinToId,
                                                    value: value,
                                                    minimumValueToBuy: minimumValueToBuyValue)
              self.data = data.encode()
            }

            coinFromField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellCoinTransactionData()
              }
            }

            coinToField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellCoinTransactionData()
              }
            }

            amountField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              amountField.value = retValue
              return retValue
            }
            amountField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            amountField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellCoinTransactionData()
              }
            }
            fields.append(amountField)

            minimumValueToBuyField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              minimumValueToBuyField.value = retValue
              return retValue
            }
            minimumValueToBuyField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellCoinTransactionData()
              }
            }
            minimumValueToBuyField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            fields.append(minimumValueToBuyField)

          case .sellAllCoins:
            let typeField = Field(key: "Type".localized(), value: "Sell All".localized(), isEditable: false)
            fields.append(typeField)
            
            guard let coinFromData = items[0].data,
              let coinFrom = self.coinBy(coinIdData: coinFromData)?.symbol,
              let coinToData = items[1].data,
              let coinTo = self.coinBy(coinIdData: coinToData)?.symbol,
              let minimumValueToBuyData = items[2].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }

            let minimumValueToBuy = BigUInt(minimumValueToBuyData)
            let minimumValueToBuyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: minimumValueToBuy) ?? 0).PIPToDecimal(),
                                                                                   formatter: decimalFormatter,
                                                                                   maxPlaces: 18)

            var coinFromField = Field(key: "Coin From".localized(), value: coinFrom, isEditable: true)
            coinFromField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinFromField.value = retValue
              return retValue
            }
            coinFromField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            fields.append(coinFromField)

            var coinToField = Field(key: "Coin To".localized(), value: coinTo, isEditable: true)
            coinToField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinToField.value = retValue
              return retValue
            }
            coinFromField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            fields.append(coinToField)

            var minimumValueToBuyField = Field(key: "Minimum Value To Buy".localized(), value: minimumValueToBuyString, isEditable: true)
            minimumValueToBuyField.keyboardType = .decimalPad

            func makeSellAllTransactionData() {
              guard
                let coinFrom = coinFromField.value, coinFrom.isValidCoin(),
                let coinFromId = self.dependency.coinService.coinId(symbol: coinFrom),
                let coinTo = coinToField.value, coinTo.isValidCoin(),
                let coinToId = self.dependency.coinService.coinId(symbol: coinTo),
                let minimumValueToBuy = minimumValueToBuyField.value, let minimumValueToBuyAmount = Decimal(str: minimumValueToBuy),
                let minimumValueToBuyValue = BigUInt(decimal: minimumValueToBuyAmount.decimalFromPIP())
              else {
                self.data = nil
                return
              }
              let sellAllData = SellAllCoinsRawTransactionData(coinFromId: coinFromId,
                                                               coinToId: coinToId,
                                                               minimumValueToBuy: minimumValueToBuyValue)
              self.data = sellAllData.encode()
            }

            coinFromField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellAllTransactionData()
              }
            }

            coinToField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellAllTransactionData()
              }
            }

            minimumValueToBuyField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              minimumValueToBuyField.value = retValue
              return retValue
            }
            minimumValueToBuyField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeSellAllTransactionData()
              }
            }
            minimumValueToBuyField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            fields.append(minimumValueToBuyField)

          case .buyCoin:
            let typeField = Field(key: "Type".localized(), value: "Buy Coin".localized(), isEditable: false)
            fields.append(typeField)

            guard let coinFromData = items[2].data,
              let coinFrom = self.coinBy(coinIdData: coinFromData)?.symbol,
              let valueData = items[1].data,
              let coinToData = items[0].data,
              let coinTo = self.coinBy(coinIdData: coinToData)?.symbol,
              let maximumValueToSpendData = items[3].data,
              coinTo.isValidCoin(),
              coinFrom.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let maximumValueToSpend = BigUInt(maximumValueToSpendData)
            let value = BigUInt(valueData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter,
                                                                        maxPlaces: 18)

            let maximumValueToSpendString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: maximumValueToSpend) ?? 0).PIPToDecimal(),
                                                                                   formatter: decimalFormatter,
                                                                                   maxPlaces: 18)
            
            var coinToField = Field(key: "Coin To Buy".localized(), value: coinTo, isEditable: true)
            coinToField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinToField.value = retValue
              return retValue
            }
            coinToField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }

            var amountField = Field(key: "Amount".localized(), value: amountString, isEditable: true)
            amountField.keyboardType = .decimalPad

            var coinFromField = Field(key: "Coin To Sell".localized(), value: coinFrom, isEditable: true)
            coinFromField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinFromField.value = retValue
              return retValue
            }
            coinFromField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }

            var maximumValueToSpendField = Field(key: "Maximum Value To Spend".localized(), value: maximumValueToSpendString, isEditable: true)
            maximumValueToSpendField.keyboardType = .decimalPad

            func makeBuyCoinTransactionData() {
              guard
                let coinFrom = coinFromField.value, coinFrom.isValidCoin(),
                let coinFromId = self.dependency.coinService.coinId(symbol: coinFrom),
                let coinTo = coinToField.value, coinTo.isValidCoin(),
                let coinToId = self.dependency.coinService.coinId(symbol: coinTo),
                let amount = amountField.value, let decimalAmount = Decimal(str: amount),
                let value = BigUInt(decimal: decimalAmount.decimalFromPIP()),
                let maximumValueToSpend = maximumValueToSpendField.value, let maximumValueToSpendAmount = Decimal(str: maximumValueToSpend),
                let maximumValueToSpendValue = BigUInt(decimal: maximumValueToSpendAmount.decimalFromPIP())
              else {
                self.data = nil
                return
              }

              let data = BuyCoinRawTransactionData(coinFromId: coinFromId,
                                                   coinToId: coinToId,
                                                   value: value,
                                                   maximumValueToSell: maximumValueToSpendValue)
              self.data = data.encode()
            }

            coinFromField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeBuyCoinTransactionData()
              }
            }
            fields.append(coinFromField)

            coinToField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeBuyCoinTransactionData()
              }
            }
            fields.append(coinToField)

            amountField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              amountField.value = retValue
              return retValue
            }
            amountField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            amountField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeBuyCoinTransactionData()
              }
            }
            fields.append(amountField)

            maximumValueToSpendField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              maximumValueToSpendField.value = retValue
              return retValue
            }
            maximumValueToSpendField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeBuyCoinTransactionData()
              }
            }
            maximumValueToSpendField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            fields.append(maximumValueToSpendField)

          case .createCoin, .recreateCoin:
            if type == .recreateCoin {
              let typeField = Field(key: "Type".localized(), value: "Recreate Coin".localized(), isEditable: false)
              fields.append(typeField)
            } else {
              let typeField = Field(key: "Type".localized(), value: "Create Coin".localized(), isEditable: false)
              fields.append(typeField)
            }
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
                                                                               formatter: decimalFormatter,
                                                                               maxPlaces: 18)

            let initialReserveString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialReserve) ?? 0).PIPToDecimal(),
                                                                                formatter: decimalFormatter,
                                                                                maxPlaces: 18)

            let crrString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: crr) ?? 0),
                                                                     formatter: noMantissaFormatter)
            let coinNameField = Field(key: "Coin Name".localized(), value: coinName, isEditable: false)
            fields.append(coinNameField)

            let coinSymbolField = Field(key: "Coin Symbol".localized(), value: coinSymbol, isEditable: false)
            fields.append(coinSymbolField)

            let initialAmountField = Field(key: "Coin Symbol".localized(), value: initialAmountString, isEditable: false)
            fields.append(initialAmountField)

            let initialReserveField = Field(key: "Initial Reserve".localized(), value: initialReserveString, isEditable: false)
            fields.append(initialReserveField)

            let crrField = Field(key: "Constant Reserve Ratio".localized(), value: crrString, isEditable: false)
            fields.append(crrField)

            if let maxSupplyData = items[safe: 5]?.data {
              let maxSupply = BigUInt(maxSupplyData)
              let maxSupplyString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: maxSupply) ?? 0).PIPToDecimal(),
                                                                             formatter: decimalFormatter,
                                                                             maxPlaces: 18)

              let maxSupplyField = Field(key: "Max Supply".localized(),
                                         value: BigUInt.compare(maxSupply, BigUInt(decimal: Decimal(pow(10.0, 18.0+15.0)))!) == .orderedSame ? "10¹⁵ (max)" : maxSupplyString,
                                         isEditable: false)
              fields.append(maxSupplyField)
            } else {
              let maxSupplyField = Field(key: "Max Supply".localized(), value: "10¹⁵ (max)", isEditable: false)
              fields.append(maxSupplyField)
            }

          case .declareCandidacy:
            let typeField = Field(key: "Type".localized(), value: "Declare Candidacy".localized(), isEditable: false)
            fields.append(typeField)

            guard
              let addressData = items[0].data,
              let publicKeyData = items[1].data,
              let commissionData = items[2].data,
              let coinData = items[3].data,
              let coin = self.coinBy(coinIdData: coinData)?.symbol,
              let stakeData = items[4].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let commission = BigUInt(commissionData)
            let commissionString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: commission) ?? 0),
                                                                            formatter: noMantissaFormatter)

            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter)
            let addressField = Field(key: "Address".localized(), value: "Mx" + addressData.toHexString(), isEditable: false)
            fields.append(addressField)

            let pkField = Field(key: "Public Key".localized(), value:  "Mp" + publicKeyData.toHexString(), isEditable: false)
            fields.append(pkField)

            let commissionField = Field(key: "Commission".localized(), value:  commissionString, isEditable: false)
            fields.append(commissionField)

            let coinField = Field(key: "Coin".localized(), value: coin, isEditable: false)
            fields.append(coinField)

            let stakeField = Field(key: "Stake".localized(), value: amountString, isEditable: false)
            fields.append(stakeField)

          case .delegate:
            let typeField = Field(key: "Type".localized(), value: "Delegate".localized(), isEditable: false)
            fields.append(typeField)

            guard
              let publicKeyData = items[0].data,
              let coinData = items[1].data,
              let coin = self.coinBy(coinIdData: coinData)?.symbol,
              let stakeData = items[2].data,
              coin.isValidCoin() else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter,
                                                                        maxPlaces: 18)

            self.neededCoin = coin
            self.neededCoinAmount = (Decimal(bigInt: stake) ?? 0).PIPToDecimal()

            var pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: true)

            var coinField = Field(key: "Coin".localized(), value: coin, isEditable: true)

            var amountField = Field(key: "Amount".localized(), value: amountString, isEditable: true)
            amountField.keyboardType = .decimalPad

            func makeDelegateTransactionData() {
              guard
                let publicKey = pkField.value, publicKey.isValidPublicKey(),
                let coin = coinField.value, coin.isValidCoin(),
                let coinId = self.dependency.coinService.coinId(symbol: coin),
                let amount = amountField.value, let decimalAmount = Decimal(str: amount),
                let value = BigUInt(decimal: decimalAmount.decimalFromPIP())
              else {
                self.data = nil
                return
              }

              let data = DelegateRawTransactionData(publicKey: publicKey,
                                                    coinId: coinId,
                                                    value: value)
              self.data = data.encode()
            }

            coinField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinField.value = retValue
              return retValue
            }
            coinField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            coinField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeDelegateTransactionData()
              }
            }

            amountField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              amountField.value = retValue
              return retValue
            }
            amountField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            amountField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeDelegateTransactionData()
              }
            }

            pkField.modify = { val in
              let retValue = val
              pkField.value = retValue
              return retValue
            }
            pkField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidPublicKey() ?? false) ? nil : "Invalid Public Key".localized()
            }
            pkField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeDelegateTransactionData()
              }
            }
            fields.append(pkField)
            fields.append(coinField)
            fields.append(amountField)

          case .unbond:
            let typeField = Field(key: "Type".localized(), value: "Unbond".localized(), isEditable: false)
            fields.append(typeField)
            guard
              let publicKeyData = items[0].data,
              let coinData = items[1].data,
              let coin = self.coinBy(coinIdData: coinData)?.symbol,
              let stakeData = items[2].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let stake = BigUInt(stakeData)
            let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
                                                                        formatter: decimalFormatter,
                                                                        maxPlaces: 18)

            var pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: true)

            var coinField = Field(key: "Coin".localized(), value: coin, isEditable: true)

            var amountField = Field(key: "Amount".localized(), value: amountString, isEditable: true)
            amountField.keyboardType = .decimalPad

            func makeUnbondTransactionData() {
              guard
                let publicKey = pkField.value, publicKey.isValidPublicKey(),
                let coin = coinField.value, coin.isValidCoin(),
                let coinId = self.dependency.coinService.coinId(symbol: coin),
                let amount = amountField.value, let decimalAmount = Decimal(str: amount),
                let value = BigUInt(decimal: decimalAmount.decimalFromPIP())
              else {
                self.data = nil
                return
              }

              let data = UnbondRawTransactionData(publicKey: publicKey,
                                                  coinId: coinId,
                                                  value: value)
              self.data = data.encode()
            }

            coinField.modify = { [weak self] val in
              let retValue = self?.fieldModifyCoin(val)
              coinField.value = retValue
              return retValue
            }
            coinField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidCoin() ?? false) ? nil : "Invalid coin name".localized()
            }
            coinField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeUnbondTransactionData()
              }
            }

            amountField.modify = { [weak self] val in
              let retValue = self?.fieldModifyAmount(val)
              amountField.value = retValue
              return retValue
            }
            amountField.validateWithError = { val in
              return (Decimal(str: val) != nil || val?.count == 0) ? nil : "Invalid value".localized()
            }
            amountField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeUnbondTransactionData()
              }
            }

            pkField.modify = { val in
              let retValue = val
              pkField.value = retValue
              return retValue
            }
            pkField.validateWithError = { val in
              return (val?.count == 0 || val?.isValidPublicKey() ?? false) ? nil : "Invalid Public Key".localized()
            }
            pkField.onChanged = {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                makeUnbondTransactionData()
              }
            }

            fields.append(pkField)
            fields.append(coinField)
            fields.append(amountField)

          case .redeemCheck:
            let typeField = Field(key: "Type".localized(), value: "Redeem Check".localized(), isEditable: false)
            fields.append(typeField)

            guard let checkData = items[0].data,
                  let checkPayload = RLP.decode(checkData)?[0]?.content else {
              throw RawTransactionViewModelError.incorrectTxData
            }

            switch checkPayload {
            case .list(let checkPayloadItems, _, _):
              if
                let checkCoinData = checkPayloadItems[safe: 3]?.data,
                let checkAmount = checkPayloadItems[safe: 4]?.data,
                let checkGasData = checkPayloadItems[safe: 5]?.data {
                let value = BigUInt(checkAmount)
                let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
                let amountString = decimalFormatter.formattedDecimal(with: amount)
                let checkValue = amountString + " " + (String(coinData: checkCoinData) ?? "")
                let amountField = Field(key: "Amount".localized(), value: checkValue, isEditable: false)
                fields.append(amountField)

                let checkGasBigInt = BigUInt(checkGasData)
                if let gasCoin = self.dependency.coinService.coinWith(predicate: { (coin) -> (Bool) in
                  guard let id = coin.id else { return false }
                  return checkGasBigInt == BigUInt(id)
                })?.symbol {
                  self.gasCoin = gasCoin
                }
              }
            case .noItem, .data(_):
              break
            }

            let checkField = Field(key: "Check".localized(), value: "Mc" + checkData.toHexString(), isEditable: false)
            fields.append(checkField)
            if let passwordString = userData?["p"] as? String {
              let passwordField = Field(key: "Password".localized(), value: passwordString, isEditable: false)
              fields.append(passwordField)
            } else if let proofData = items[1].data, proofData.count > 0 {
              let proofField = Field(key: "Proof".localized(), value: proofData.toHexString(), isEditable: false)
              fields.append(proofField)
            } else {
              throw RawTransactionViewModelError.incorrectTxData
            }

          case .setCandidateOnline, .setCandidateOffline:
            if type == .setCandidateOnline {
              let typeField = Field(key: "Type".localized(), value: "Set Candidate On".localized(), isEditable: false)
              fields.append(typeField)
            } else {
              let typeField = Field(key: "Type".localized(), value: "Set Candidate Off".localized(), isEditable: false)
              fields.append(typeField)
            }

            guard let publicKeyData = items[0].data else {
              throw RawTransactionViewModelError.incorrectTxData
            }
            let pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: false)
            fields.append(pkField)

          case .createMultisigAddress, .editMultisigOwner:
            if type == .editMultisigOwner {
              let typeField = Field(key: "Type".localized(), value: "Edit Multisig Address".localized(), isEditable: false)
              fields.append(typeField)
            } else {
              let typeField = Field(key: "Type".localized(), value: "Create Multisig Address".localized(), isEditable: false)
              fields.append(typeField)
            }
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

              let field = Field(key: "Address : Weight".localized(),
                                value: TransactionTitleHelper.title(from: address) + " : " + weightString,
                                isEditable: false)
              fields.append(field)
            }
            let threshold = BigUInt(thresholdData)
            let thresholdString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: threshold) ?? 0),
                                                                           formatter: noMantissaFormatter)
            let thresholdField = Field(key: "Threshold".localized(), value: thresholdString, isEditable: false)
            fields.append(thresholdField)

          case .multisend:
            guard let arrayData = items[0].data, let array = RLP.decode(arrayData) else {
              throw RawTransactionViewModelError.incorrectTxData
            }
            multisendAddressCount = array.count ?? 0
            for idx in 0..<(array.count ?? 0) {
              if
                let addressDictData = array[idx]?.data,
                let addressDict = RLP.decode(addressDictData),
                let coinData = addressDict[0]?.data,
                let coin = self.coinBy(coinIdData: coinData)?.symbol,
                let addressData = addressDict[1]?.data,
                let valueData = addressDict[2]?.data {
                  let address = addressData.toHexString()
                  let value = BigUInt(valueData)
                  let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
                  let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                              formatter: decimalFormatter,
                                                                              maxPlaces: 18)
                  let sendingValue = amountString + " " + coin

                  let sendingField = Field(key: "You are Sending".localized(), value: sendingValue, isEditable: false)
                  fields.append(sendingField)

                  let toField = Field(key: "To".localized(), value: "Mx" + address, isEditable: false)
                  fields.append(toField)
              }
            }

          case .editCandidate:
            let typeField = Field(key: "Type".localized(), value: "Edit Candidate".localized(), isEditable: false)
            fields.append(typeField)

            guard let publicKeyData = items[0].data,
              let rewardAddressData = items[1].data,
              let ownerAddressData = items[2].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: false)
            fields.append(pkField)

            let rewardField = Field(key: "Reward Address".localized(), value: "Mx" + rewardAddressData.toHexString(), isEditable: false)
            fields.append(rewardField)

            let ownerField = Field(key: "Owner Address".localized(), value: "Mx" + ownerAddressData.toHexString(), isEditable: false)
            fields.append(ownerField)

          case .editCandidatePublicKey:
            let typeField = Field(key: "Type".localized(), value: "Edit Candidate Public Key".localized(), isEditable: false)
            fields.append(typeField)

            guard let publicKeyData = items[0].data,
              let newPublicKeyData = items[1].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: false)
            fields.append(pkField)

            let newPkField = Field(key: "New Public Key".localized(), value: "Mp" + newPublicKeyData.toHexString(), isEditable: false)
            fields.append(newPkField)

          case .setHaltBlock:
            let typeField = Field(key: "Type".localized(), value: "Set Halt Block".localized(), isEditable: false)
            fields.append(typeField)

            guard let publicKeyData = items[0].data,
              let heightData = items[1].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }

            let pkField = Field(key: "Public Key".localized(), value: "Mp" + publicKeyData.toHexString(), isEditable: false)
            fields.append(pkField)

            let height = "\(BigUInt(heightData))"
            let heightField = Field(key: "Height".localized(), value: height, isEditable: false)
            fields.append(heightField)

          case .changeCoinOwner:
            let typeField = Field(key: "Type".localized(), value: "Change Coin Owner".localized(), isEditable: false)
            fields.append(typeField)

            guard
              let coinData = items[0].data,
              let coin = String(coinData: coinData),
              let addressData = items[1].data else {
                throw RawTransactionViewModelError.incorrectTxData
            }
            let coinField = Field(key: "Coin".localized(), value: coin, isEditable: false)
            fields.append(coinField)

            let addressField = Field(key: "To".localized(), value: "Mx" + addressData.toHexString(), isEditable: false)
            fields.append(addressField)

          case .priceVote:
            let typeField = Field(key: "Type".localized(), value: "Price Vote".localized(), isEditable: false)
            fields.append(typeField)

            guard let price = items[0].data else {
              throw RawTransactionViewModelError.incorrectTxData
            }

            let priceField = Field(key: "Price".localized(), value: "\(BigUInt(price))".localized(), isEditable: false)
            fields.append(priceField)
            
          default:
            break
          }
          break

        case .noItem, .data(_): break
      }

      if gasCoin.isValidCoin() {
        let gasField = Field(key: "Gas Coin".localized(), value: gasCoin, isEditable: false)
        fields.append(gasField)
      }

      if let payload = payload, payload.count > 0 {
        fields.append(payloadField)
      } else if isEditing.value {
        fields.append(payloadField)
      }
    }
	}

  func coinBy(coinIdData: Data) -> Coin? {
    let coinId = BigUInt(coinIdData)
    return self.dependency.coinService.coinWith(predicate: { (coin) -> (Bool) in
      guard let id = coin.id else { return false }
      return coinId == BigUInt(id)
    })
  }

}

extension RawTransactionViewModel: LastBlockViewable {}

extension RawTransactionViewModel {

  func fieldModifyCoin(_ val: String?) -> String? {
    return val?.replacingOccurrences(of: " ", with: "").uppercased()
  }

  func fieldModifyAmount(_ val: String?) -> String? {
    return val?
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: ",", with: ".")
  }

}
