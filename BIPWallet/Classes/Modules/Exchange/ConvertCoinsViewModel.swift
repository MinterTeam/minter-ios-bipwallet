//
//  ConvertCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer
import RxRelay

class ConvertCoinsViewModel: BaseViewModel {

  typealias ExchangeSuccessResult = (message: String?, transactionHash: String?)

  var balanceService: BalanceService
  var coinService: CoinService
  var gateService: GateService

	var accountManager = AccountManager()

	var selectedCoin: String? {
		didSet {
			selectedCoin = selectedCoin?.uppercased()
				.trimmingCharacters(in: .whitespacesAndNewlines)
		}
	}
  var baseCoin: Coin {
    return gateService.lastComission?.coin ?? Coin.baseCoin()
  }

  var approximatelyReady = BehaviorSubject<Bool>(value: false)
  var spendCoinField = ReplaySubject<String?>.create(bufferSize: 2)
	var hasCoin = Variable<Bool>(false)
	var coinIsLoading = Variable(false)
	var getCoin = BehaviorSubject<String?>(value: "")
	var shouldClearForm = Variable(false)
	var amountError = Variable<String?>(nil)
	var getCoinError = PublishSubject<String?>()
  lazy var isApproximatelyLoading = PublishSubject<Bool>()
  lazy var isPoolExhange = BehaviorRelay<Bool>(value: false)
  lazy var poolPath = BehaviorRelay<[Int]>(value: [])
	lazy var isLoading = BehaviorSubject<Bool>(value: false)
	lazy var errorNotification = PublishSubject<String?>()
	lazy var successMessage = PublishSubject<String?>()
  lazy var exchangeSucceeded = PublishSubject<ExchangeSuccessResult>()
	let formatter = CurrencyNumberFormatter.coinFormatter
	var currentGas = RawTransactionDefaultGasPrice
  lazy var feeObservable = ReplaySubject<String>.create(bufferSize: 1)
	var baseCoinCommission: Decimal {
    let additionalFee = self.poolPath.value.count > 2 ? Decimal(poolPath.value.count - 2) * (gateService.lastComission?.transactionCommissions[.sellPoolDelta]?.PIPToDecimal() ?? 0.0) : 0.0
    let commission = !self.isPoolExhange.value ? (gateService.lastComission?.transactionCommissions[.buyBancor]?.PIPToDecimal() ?? 0.0) :
      ((gateService.lastComission?.transactionCommissions[.sellPoolBase]?.PIPToDecimal() ?? 0.0) + additionalFee)
    return (Decimal(currentGas) * commission)
	}
  var hasMultipleCoinsObserver: Observable<Bool> {
    return balanceService.balances().map { (value) -> Bool in
      value.balances.keys.count > 1
    }
  }
  var endEditing = PublishSubject<Void>()
  var showConfirmation = PublishSubject<(String?, String?)>()
  var showReceived = PublishSubject<String?>()

	// MARK: -

  init(balanceService: BalanceService, coinService: CoinService, gateService: GateService) {
    self.balanceService = balanceService
    self.coinService = coinService
    self.gateService = gateService

		super.init()

    self.selectedCoin = self.baseCoin.symbol!//Coin.baseCoin().symbol!

    balanceService.balances().subscribe(onNext: { [weak self] (val) in
      guard let self = self else { return; }
      let balances = val.balances

      self.balances = balances.mapValues({ (val) -> Decimal in
        return val.0
      })

      if self.selectedCoin == nil {
        self.selectedCoin = self.baseCoin.symbol//Coin.baseCoin().symbol!
      }

      var spendCoinSource = [String: Decimal]()
      balances.keys.forEach({ (coin) in
        spendCoinSource[coin] = balances[coin]?.0 ?? 0.0
      })

      self.spendCoinPickerSource = spendCoinSource

      if self.selectedCoin != nil {
        self.spendCoinField.onNext(self.spendCoinText)
      }
    }).disposed(by: disposeBag)

    gateService.updateGas()
    Observable.combineLatest(poolPath.asObservable(), approximatelyReady.asObservable(), gateService.currentGas())
      .withLatestFrom(gateService.currentGas())
      .startWith(RawTransactionDefaultGasPrice)
      .subscribe(onNext: { [weak self] (val) in
        self?.currentGas = val
        let commissionCoin = self?.gateService.lastComission?.coin?.symbol ?? ""
        let fee = CurrencyNumberFormatter.decimalFormatter.formattedDecimal(with: self?.baseCoinCommission ?? 0.0) + " " + commissionCoin
        self?.feeObservable.onNext(fee)
      }).disposed(by: disposeBag)

    getCoin.distinctUntilChanged()
      .do(onNext: { [weak self] (term) in
        if nil != term && term != "" {
          self?.hasCoin.value = false
          self?.getCoinError.onNext("COIN NOT FOUND".localized())
        } else {
          self?.getCoinError.onNext("")
        }
      }).map({ (term) -> String in
        return term?.transformToCoinName() ?? ""
      }).filter({ (term) -> Bool in
        return CoinValidator.isValid(coin: term)
      }).flatMap { (term) -> Observable<Event<Bool>> in
        return self.coinService.coinExists(name: term).materialize()
      }.subscribe(onNext: { [weak self] (event) in
        switch event {
        case .completed:
          break
        case .next(let hasCoin):
          self?.hasCoin.value = hasCoin
          if hasCoin {
            self?.getCoinError.onNext("")
          }
        case .error(_):
          break
        }
      }).disposed(by: disposeBag)

	}

  var selectedBalance: Decimal {
    guard let selectedCoin = selectedCoin else {
      return 0.0
    }
    return balances[selectedCoin] ?? 0.0
  }

  var balances = [String: Decimal]()

  var baseCoinBalance: Decimal {
    return balances[self.baseCoin.symbol ?? ""] ?? 0.0
  }

	var hasMultipleCoins: Bool = false

	func canPayComissionWithBaseCoin() -> Bool {
		let balance = self.baseCoinBalance
		if balance >= self.baseCoinCommission {
			return true
		}
		return false
	}

	var selectedBalanceString: String? {
    return CurrencyNumberFormatter.decimalFormatter.formattedDecimal(with: selectedBalance)
	}

	var spendCoinText: String {
		let selected = (selectedCoin ?? "")
		let bal = formatter.formattedDecimal(with: selectedBalance)
		return selected + " (" + bal + ")"
	}

	// MARK: -

  var spendCoinPickerSource = [String: Decimal]()

	// MARK: -

	func validateErrors() {}

	func loadCoin() {
		self.hasCoin.value = false
		let coin = try? self.getCoin.value()?
			.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
		guard coin?.isValidCoin() ?? false else {
			//Show error
			return
		}

    if coin == self.baseCoin.symbol {
			hasCoin.value = true
			self.validateErrors()
			return
		}
	}

  func coins(by term: String, completion: (([Coin]) -> ())?) {}

}

extension ConvertCoinsViewModel: LUAutocompleteViewDelegate, LUAutocompleteViewDataSource {

  func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect text: AutocompleteModel) {
    getCoin.onNext(text.description)
    endEditing.onNext(())
  }

  func autocompleteView(_ autocompleteView: LUAutocompleteView,
                        elementsFor text: String,
                        completion: @escaping ([AutocompleteModel]) -> Void) {
    self.coins(by: text) { (coins) in

      let coinsArray = coins.compactMap({ (coin) -> TextAutocompleteModel in
        return TextAutocompleteModel(shouldShowCheckmark: coin.isOracleVerified, text: coin.symbol ?? "")
      })

      completion(Array(coinsArray[safe: 0..<3] ?? []))
    }
  }

}
