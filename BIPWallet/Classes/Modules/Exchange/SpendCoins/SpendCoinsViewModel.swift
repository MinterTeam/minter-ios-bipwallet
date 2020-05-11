//
//  SpendCoinsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt
import MinterCore

enum SpendCoindsViewModelError: Error {
  case incorrectParams
  case noPrivateKey
  case canNotGetNonce
  case canNotCreateTx
}

class SpendCoinsViewModel: ConvertCoinsViewModel, ViewModel {

  // MARK: - ViewModel

  var input: SpendCoinsViewModel.Input!
  var output: SpendCoinsViewModel.Output!
  var dependency: SpendCoinsViewModel.Dependency!

  struct Input {
    var spendAmount: BehaviorRelay<String?>
    var getCoin: AnyObserver<String?>
    var spendCoin: AnyObserver<String?>
    var useMaxDidTap: AnyObserver<Void>
    var didTapExchangeButton: AnyObserver<Void>
    var selectedAddress: String?
    var selectedCoin: String?
  }

  struct Output {
    var approximately: Observable<String?>
    var spendCoin: Observable<String?>
    var spendAmount: Observable<String?>
    var hasMultipleCoinsObserver: Observable<Bool>
    var isButtonEnabled: Observable<Bool>
    var isLoading: Observable<Bool>
    var isCoinLoading: Observable<Bool>
    var errorNotification: Observable<String?>
    var shouldClearForm: Observable<Bool>
    var amountError: Observable<String?>
    var getCoinError: Observable<String?>
  }

  struct Dependency {
    var coinService: CoinService
    var balanceService: BalanceService
    var gateService: GateService
  }

  init(dependency: Dependency) {
    super.init(balanceService: dependency.balanceService,
               coinService: dependency.coinService,
               gateService: dependency.gateService)

    self.output = Output(approximately: approximately.asObservable(),
                         spendCoin: spendCoinField.asObservable(),
                         spendAmount: spendAmount.asObservable(),
                         hasMultipleCoinsObserver: hasMultipleCoinsObserver,
                         isButtonEnabled: isButtonEnabled,
                         isLoading: isLoading.asObservable(),
                         isCoinLoading: coinIsLoading.asObservable(),
                         errorNotification: errorNotification.asObservable(),
                         shouldClearForm: shouldClearForm.asObservable(),
                         amountError: amountError.asObservable(),
                         getCoinError: getCoinError.asObservable())

    self.input = Input(spendAmount: spendAmount,
                       getCoin: getCoin.asObserver(),
                       spendCoin: spendCoinField.asObserver(),
                       useMaxDidTap: useMaxDidTap.asObserver(),
                       didTapExchangeButton: didTapExchangeButton.asObserver(),
                       selectedCoin: selectedCoin)
    self.dependency = dependency

    bind()
  }

  private func bind() {

    spendAmount.distinctUntilChanged().debounce(.seconds(1), scheduler: MainScheduler.instance).map { (val) -> String? in
      return AmountHelper.transformValue(value: val)
    }.subscribe(onNext: { val in
      self.spendAmount.accept(val)
    }).disposed(by: disposeBag)

    spendCoinField
      .throttle(1.0, scheduler: MainScheduler.instance)
      .distinctUntilChanged().map({ (val) -> SpendCoinPickerItem? in
        let item = SpendCoinPickerItem.items(with: self.spendCoinPickerSource).filter({ (item) -> Bool in
          return item.title == val
        }).first
        return item
      }).filter({ (item) -> Bool in
        return item != nil
      }).subscribe(onNext: { [weak self] (item) in
        self?.selectedCoin = item?.coin
        self?.spendCoin.onNext(item?.coin)
      }).disposed(by: disposeBag)

    spendCoin
      .distinctUntilChanged()
      .asObservable()
      .filter({ [weak self] (coin) -> Bool in
        return coin != nil && self?.selectedBalance != nil
      }).subscribe(onNext: { [weak self] (coin) in
        guard let _self = self else { return } //swiftlint:disable:this identifier_name
        let item = SpendCoinPickerItem(coin: coin!,
                                       balance: _self.selectedBalance,
                                       formatter: _self.formatter)
        self?.spendCoinField.onNext(item.title)
    }).disposed(by: disposeBag)

    Observable.combineLatest(spendCoin.asObservable(),
                             spendAmount.asObservable(),
                             getCoin.asObservable())
      .distinctUntilChanged({ (val1, val2) -> Bool in
        return val1.0 == val2.0 && val1.1 == val2.1 && val1.2 == val2.2
      }).throttle(1, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] (val) in
        self?.minimumValueToBuy.value = nil
        self?.approximately.onNext("")
        self?.validateErrors()

        if let from = self?.selectedCoin?.transformToCoinName(),
          let to = val.2?.transformToCoinName(),
          let amountString = val.1?.replacingOccurrences(of: " ", with: ""),
          let amnt = Decimal(string: amountString), amnt > 0 {
          self?.calculateApproximately(fromCoin: from, amount: amnt, getCoin: to)
        }
      }).disposed(by: disposeBag)

    approximatelyReady.asObservable().subscribe(onNext: { [weak self] (_) in
      self?.validateErrors()
    }).disposed(by: disposeBag)

    didTapExchangeButton.asObservable().subscribe(onNext: { [weak self] _ in
      self?.exchange()
    }).disposed(by: disposeBag)

    shouldClearForm.asObservable().subscribe(onNext: { [weak self] (_) in
      self?.spendAmount.accept(nil)
      self?.getCoin.onNext("")
      self?.validateErrors()
    }).disposed(by: disposeBag)

    useMaxDidTap
      .withLatestFrom(Observable.combineLatest(spendCoin, dependency.balanceService.balances()))
      .subscribe(onNext: { [weak self] (val) in
        guard let spendCoin = val.0, let selectedBalance = val.1.balances[spendCoin]?.0 else { return }
        
        guard let _self = self else { return } //swiftlint:disable:this identifier_name
        let selectedAmount = CurrencyNumberFormatter.formattedDecimal(with: selectedBalance,
                                                                      formatter: _self.decimalFormatter)
        self?.spendAmount.accept(selectedAmount)
    }).disposed(by: disposeBag)
  }

  // MARK: -

  let useMaxDidTap = PublishSubject<Void>()
  let didTapExchangeButton = PublishSubject<Void>()
  var spendCoin = BehaviorSubject<String?>(value: nil)
  var spendAmount = BehaviorRelay<String?>(value: nil)

  private var approximately = PublishSubject<String?>()
  var approximatelyReady = Variable<Bool>(false)
  var minimumValueToBuy = Variable<Decimal?>(nil)

  private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
  private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter

  lazy var isButtonEnabled: Observable<Bool> =
    Observable
      .combineLatest(getCoin.asObservable(),
                     spendAmount.asObservable(),
                     spendCoin.asObservable(),
                     isLoading.asObservable(),
                     approximatelyReady.asObservable()
      ).map({ (val) -> Bool in
        let getCoin = val.0?.transformToCoinName()
        let spendAmount = val.1
        let spendCoin = val.2?.transformToCoinName()
        let isLoading = val.3
        let approximatelyReady = val.4

        guard !isLoading && approximatelyReady else {
          return false
        }

        guard let amountString = val.1,
          let amnt = Decimal(string: amountString),
          AmountValidator.isValid(amount: amnt) else {
          return false
        }

        guard getCoin != (self.selectedCoin ?? "") else {
          return false
        }
        return CoinValidator.isValid(coin: getCoin) && CoinValidator.isValid(coin: spendCoin)
      })

  // MARK: -

  private func calculateApproximately(fromCoin: String, amount: Decimal, getCoin: String) {
    approximatelyReady.value = false

    guard let maxComparableBalance = Decimal.PIPComparableBalance(from: selectedBalance) else {
      return
    }

    var value = amount.decimalFromPIP()
    let isMax = (value > 0 && value == maxComparableBalance)
    if isMax {
      value = (selectedBalance).decimalFromPIP()
    }

    if !CoinValidator.isValid(coin: getCoin) {
      return
    }

    GateManager.shared.estimateCoinSell(coinFrom: fromCoin,
                                        coinTo: getCoin.transformToCoinName(),
                                        value: value,
                                        isAll: isMax)
      .do(onError: { [weak self] (error) in
        if
          let err = error as? HTTPClientError,
          let log = err.userData?["message"] as? String {
          self?.approximately.onNext(log)
          return
        } else if
          let err = error as? HTTPClientError,
          let log = err.userData?["log"] as? String {
          self?.approximately.onNext(log)
          return
        }

        if self?.hasCoin.value == true {
          self?.approximately.onNext("Estimate can't be calculated at the moment".localized())
        }
    }).subscribe(onNext: { [weak self] (res) in
      guard let _self = self else { return } //swiftlint:disable:this identifier_name

      let ammnt = res.0
      let val = ammnt.PIPToDecimal()

      let appr = (CurrencyNumberFormatter.formattedDecimal(with: val > 0 ? val : 0,
                                                           formatter: _self.formatter)) + " " + getCoin
      self?.approximately.onNext(appr)

      var approximatelyRoundedVal = (ammnt * 0.9)
      approximatelyRoundedVal.round(.up)
      self?.minimumValueToBuy.value = approximatelyRoundedVal

      let gtCoin = try? self?.getCoin.value() ?? ""
      if getCoin.transformToCoinName() == gtCoin?.transformToCoinName() {
        self?.approximatelyReady.value = true
      }
    }).disposed(by: disposeBag)
  }

  override func validateErrors() {
    if
      let amountString = self.spendAmount.value,
      let amount = Decimal(string: amountString) {
        if amount > selectedBalance {
          amountError.value = "INSUFFICIENT FUNDS".localized()
        } else {
          amountError.value = nil
        }
    } else {
      let amountString = self.spendAmount.value
      if nil == amountString || amountString == "" || amountString == "," || amountString == "." {
        amountError.value = nil
      } else {
        amountError.value = "INCORRECT AMOUNT".localized()
      }
    }
  }

  func exchange() {

    guard let coinFrom = self.selectedCoin?.transformToCoinName(),
      let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
      let amount = self.spendAmount.value,
      let minimumBuyValue = self.minimumValueToBuy.value
    else {
      return
    }

    Observable<Void>.just(()).withLatestFrom(dependency.balanceService.account)
    .filter({ (account) -> Bool in
      return account != nil && (account?.address.isValidAddress() ?? false)
    }).map({ (item) -> String in
      return item?.address ?? ""
    })
    .flatMap { selectedAddress in
        return self.processExchange(coinFrom: coinFrom,
                                    coinTo: coinTo,
                                    amount: amount,
                                    selectedAddress: selectedAddress,
                                    minimumBuyValue: minimumBuyValue)
      }
      .subscribe(onNext: { [weak self] (_) in
        self?.shouldClearForm.value = true
        self?.successMessage.onNext("Coins have been exchanged".localized())
        }, onError: { [weak self] (error) in
          self?.handleError(error)
        }, onCompleted: {
          self.dependency.balanceService.updateBalance()
      }).disposed(by: self.disposeBag)
  }

  private func handleError(_ err: Error?) {
    var title = "Can't send Transaction".localized()
    if let mvError = err as? SpendCoindsViewModelError {
      switch mvError {
      case .canNotCreateTx:
        title = "Can't create transaction".localized()
      case .incorrectParams:
        title = "Incorrect params".localized()
      case .noPrivateKey:
        title = "No private key found".localized()
      case .canNotGetNonce:
        title = "Can't get nonce".localized()
      }
    }

    if
      let apiError = err as? HTTPClientError,
      let errorCode = apiError.userData?["code"] as? Int {
      if errorCode == 107 {
        title = "Not enough coins to spend".localized()
      } else if errorCode == 103 {
        title = "Coin reserve balance is not sufficient for transaction".localized()
      } else {
        if let msg = apiError.userData?["message"] as? String {
          title = msg
        } else {
          title = "An error occured".localized()
        }
      }
    }
    self.errorNotification.onNext(title)
  }

  func processExchange(coinFrom: String,
                       coinTo: String,
                       amount: String,
                       selectedAddress: String,
                       minimumBuyValue: Decimal) -> Observable<String?> {
    return Observable<String?>.create { [weak self] observer -> Disposable in
      guard let _self = self else { return Disposables.create() } //swiftlint:disable:this identifier_name

      guard let amnt = Decimal(string: amount),

        let convertVal = BigUInt(decimal: amnt, fromPIP: true),
        let maxComparableSelectedBalance = Decimal.PIPComparableBalance(from: _self.selectedBalance ?? 0.0),
        convertVal > 0 else {
          observer.onError(SpendCoindsViewModelError.incorrectParams)
          return Disposables.create()
      }

      //Getting comparable value, since we are comparing not exact numbers, but it's shortened representations
      let maxComparableBalanceString = _self.decimalsNoMantissaFormatter.string(from: maxComparableSelectedBalance as NSNumber) ?? ""
      let isMax = (convertVal > 0 && convertVal == (BigUInt(maxComparableBalanceString) ?? BigUInt(0)))

      DispatchQueue.global(qos: .userInitiated).async {
        guard let pk = _self.accountManager.privateKey(for: selectedAddress.stripMinterHexPrefix()) else {
          observer.onError(SpendCoindsViewModelError.noPrivateKey)
          return
        }

        Observable.zip(GateManager.shared.nonce(address: selectedAddress),
                       GateManager.shared.minGas()).flatMap({ (val) -> Observable<String?> in
          let nonce = Decimal(val.0 + 1)

          var tx: RawTransaction!
          let coin = _self.canPayComissionWithBaseCoin() ? Coin.baseCoin().symbol! : coinFrom
          let isBaseCoin = Coin.baseCoin().symbol! == coinFrom

          //TODO: remove after https://github.com/MinterTeam/minter-go-node/issues/224
          let minValBuy = /*minimumBuyVal*/BigUInt(0)

          //Using SellAll TX in case we're using maximum amount or there is no base coin (MNT, BIP) to pay commission
          if isMax && (isBaseCoin || !_self.canPayComissionWithBaseCoin()) {
            tx = SellAllCoinsRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                            gasPrice: val.1,
                                            gasCoin: coin,
                                            coinFrom: coinFrom,
                                            coinTo: coinTo,
                                            minimumValueToBuy: minValBuy)
          } else {
            tx = SellCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                        gasPrice: val.1,
                                        gasCoin: coin,
                                        coinFrom: coinFrom,
                                        coinTo: coinTo,
                                        value: convertVal,
                                        minimumValueToBuy: minValBuy)
          }
          let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk.raw.toHexString())
          return GateManager.shared.send(rawTx: signedTx)
        }).subscribe(onNext: { [observer] (hash) in
          observer.onNext(hash)
          observer.onCompleted()
        }, onError: { [observer] err in
          observer.onError(err)
        }).disposed(by: _self.disposeBag)
      }

      return Disposables.create()
    }.do(onCompleted: { [weak self] in
      self?.isLoading.onNext(false)
    }, onSubscribe: { [weak self] in
      self?.isLoading.onNext(true)
    }, onDispose: { [weak self] in
      self?.isLoading.onNext(false)
    })
  }

  override func coins(by term: String, completion: (([Coin]) -> ())?) {
    dependency
      .coinService
      .coins(by: term)
      .subscribe(onNext: { (coins) in
        completion?(coins)
      }).disposed(by: disposeBag)
  }

}
