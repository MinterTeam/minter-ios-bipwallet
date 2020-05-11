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

class ConvertCoinsViewModel: BaseViewModel {

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

  var spendCoinField = ReplaySubject<String?>.create(bufferSize: 2)
	var hasCoin = Variable<Bool>(false)
	var coinIsLoading = Variable(false)
	var getCoin = BehaviorSubject<String?>(value: "")
	var shouldClearForm = Variable(false)
	var amountError = Variable<String?>(nil)
	var getCoinError = PublishSubject<String?>()
	lazy var isLoading = BehaviorSubject<Bool>(value: false)
	lazy var errorNotification = PublishSubject<String?>()
	lazy var successMessage = PublishSubject<String?>()
	let formatter = CurrencyNumberFormatter.coinFormatter
	var currentGas = RawTransactionDefaultGasPrice
  lazy var feeObservable = ReplaySubject<String>.create(bufferSize: 1)
	var baseCoinCommission: Decimal {
    return (Decimal(currentGas) * RawTransactionType.buyCoin.commission()) / TransactionCoinFactorDecimal
	}
  var hasMultipleCoinsObserver: Observable<Bool> {
    return balanceService.balances().map { (value) -> Bool in
      value.balances.keys.count > 1
    }
  }

	// MARK: -

  init(balanceService: BalanceService, coinService: CoinService, gateService: GateService) {
    self.balanceService = balanceService
    self.coinService = coinService
    self.gateService = gateService

		super.init()

    self.selectedCoin = Coin.baseCoin().symbol!

    balanceService
      .balances()
      .subscribe(onNext: { [weak self] (val) in
        let balances = val.balances
        
        self?.balances = balances.mapValues({ (val) -> Decimal in
          return val.0
        })

        if self?.selectedCoin == nil {
          self?.selectedCoin = Coin.baseCoin().symbol!
        }

        var spendCoinSource = [String: Decimal]()
        balances.keys.forEach({ (coin) in
          spendCoinSource[coin] = balances[coin]?.0 ?? 0.0
        })

        self?.spendCoinPickerSource = spendCoinSource

        if self?.selectedCoin != nil {
          self?.spendCoinField.onNext(self?.spendCoinText)
        }
      }).disposed(by: disposeBag)

    gateService.updateGas()
    gateService.currentGas().startWith(RawTransactionDefaultGasPrice).subscribe(onNext: { [weak self] (val) in
        self?.currentGas = val
        let fee = CurrencyNumberFormatter.formattedDecimal(with: self?.baseCoinCommission ?? 0.0,
                                                           formatter: CurrencyNumberFormatter.decimalFormatter) + " " + (Coin.baseCoin().symbol ?? "")
				self?.feeObservable.onNext(fee)
			}).disposed(by: disposeBag)

    getCoin
      .distinctUntilChanged()
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
      })
      .flatMap { (term) -> Observable<Event<Bool>> in
        return self.coinService.coinExists(name: term).materialize()
      }
      .subscribe(onNext: { [weak self] (event) in
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
      })
      .disposed(by: disposeBag)

	}

  var selectedBalance: Decimal {
    guard let selectedCoin = selectedCoin else {
      return 0.0
    }
    return balances[selectedCoin] ?? 0.0
  }

  var balances = [String: Decimal]()

  var baseCoinBalance: Decimal {
    return balances[Coin.baseCoin().symbol!] ?? 0.0
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
    return CurrencyNumberFormatter.formattedDecimal(with: selectedBalance,
                                                    formatter: CurrencyNumberFormatter.decimalFormatter)
	}

	var spendCoinText: String {
		let selected = (selectedCoin ?? "")
		let bal = CurrencyNumberFormatter.formattedDecimal(with: selectedBalance,
																											 formatter: formatter)
		return selected + " (" + bal + ")"
	}

	// MARK: -

  var spendCoinPickerSource = [String: Decimal]()

//	func coinNames(by term: String, completion: (([String]) -> Void)?) {
////		let term = term.lowercased()
////		let coins = Session.shared.allCoins.value.filter { (con) -> Bool in
////			return (con.symbol ?? "").lowercased().starts(with: term)
////		}.sorted(by: { (coin1, coin2) -> Bool in
////			if term == (coin1.symbol ?? "").lowercased() {
////				return true
////			} else if (coin2.symbol ?? "").lowercased() == term {
////				return false
////			}
////			return (coin1.reserveBalance ?? 0) > (coin2.reserveBalance ?? 0)
////		}).map { (coin) -> String in
////			return coin.symbol ?? ""
////		}
////		let resCoins = Array(coins[safe: 0..<3] ?? [])
////		completion?(resCoins)
//	}

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

		if coin == Coin.baseCoin().symbol {
			hasCoin.value = true
			self.validateErrors()
			return
		}
	}

  func coins(by term: String, completion: (([Coin]) -> ())?) {}

}

extension ConvertCoinsViewModel: LUAutocompleteViewDelegate, LUAutocompleteViewDataSource {

  func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect text: String) {
    getCoin.onNext(text)
  }

  func autocompleteView(_ autocompleteView: LUAutocompleteView,
                        elementsFor text: String,
                        completion: @escaping ([String]) -> Void) {
    self.coins(by: text) { (coins) in
      completion(coins.map({ (coin) -> String in
        return coin.symbol ?? ""
      }).filter({ (coin) -> Bool in
        return coin != ""
      }))
    }
  }

}
