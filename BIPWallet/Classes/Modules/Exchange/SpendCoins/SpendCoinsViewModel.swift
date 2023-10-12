import Foundation
import RxSwift
import RxCocoa
import BigInt
import MinterCore
import MinterExplorer

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
    var showConfirmation: Observable<(String?, String?)>
  }

  struct Dependency {
    var coinService: CoinService
    var balanceService: BalanceService
    var gateService: GateService
    var transactionService: TransactionService
    var poolService: PoolService
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
                         getCoinError: getCoinError.asObservable(),
                         showConfirmation: showConfirmation.asObservable()
    )

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

    spendAmount.distinctUntilChanged()
      .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
      .map { (val) -> String? in
        return AmountHelper.transformValue(value: val)
      }.subscribe(onNext: { [weak self] val in
        self?.spendAmount.accept(val)
      }).disposed(by: disposeBag)

    spendCoinField.throttle(.seconds(1), scheduler: MainScheduler.instance)
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

    spendCoin.distinctUntilChanged().asObservable()
      .filter({ [weak self] (coin) -> Bool in
        return coin != nil && self?.selectedBalance != nil
      }).subscribe(onNext: { [weak self] (coin) in
        guard let _self = self else { return } //swiftlint:disable:this identifier_name
        let item = SpendCoinPickerItem(coin: coin!,
                                       balance: _self.selectedBalance,
                                       formatter: _self.formatter)
        self?.spendCoinField.onNext(item.title)
      }).disposed(by: disposeBag)

    let formObservable = Observable.combineLatest(spendCoin.asObservable(), spendAmount.asObservable(), getCoin.asObservable())
    formObservable.distinctUntilChanged({ (val1, val2) -> Bool in
      return val1.0 == val2.0 && val1.1 == val2.1 && val1.2 == val2.2
    }).throttle(.seconds(1), scheduler: MainScheduler.instance)
    .subscribe(onNext: { [weak self] (val) in
      self?.minimumValueToBuy.accept(nil)
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

    didTapExchangeButton.withLatestFrom(self.approximately.asObservable()).subscribe(onNext: { [weak self] approx in
      guard let self = self, let coinFrom = self.selectedCoin?.transformToCoinName(), let amount = self.spendAmount.value else { return }

      let fromString = CurrencyNumberFormatter.coinFormatter
        .formattedDecimal(with: Decimal(string: amount) ?? 0.0) + " " + coinFrom
      let toString = approx

      self.showConfirmation.onNext((fromString, toString))
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
        let selectedAmount = CurrencyNumberFormatter.decimalFormatter.string(from: selectedBalance as NSNumber)
//          CurrencyNumberFormatter.decimalFormatter.formattedDecimal(with: selectedBalance, maxPlaces: 18)
        self?.spendAmount.accept(selectedAmount)
      }).disposed(by: disposeBag)
  }

  // MARK: -

  let useMaxDidTap = PublishSubject<Void>()
  let didTapExchangeButton = PublishSubject<Void>()
  var spendCoin = BehaviorSubject<String?>(value: nil)
  var spendAmount = BehaviorRelay<String?>(value: nil)

  private var approximately = PublishSubject<String?>()
    var minimumValueToBuy = BehaviorRelay<Decimal?>(value: nil)

  private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
  private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter

  lazy var isButtonEnabled: Observable<Bool> =
    Observable.combineLatest(getCoin.asObservable(),
                             spendAmount.asObservable(),
                             spendCoin.asObservable(),
                             approximatelyReady.asObservable()
    ).map({ (val) -> Bool in
      let getCoin = val.0?.transformToCoinName()
      let spendAmount = val.1
      let spendCoin = val.2?.transformToCoinName()
      let approximatelyReady = val.3

      guard approximatelyReady else {
        return false
      }

      guard
        let amountString = val.1,
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
    approximatelyReady.onNext(false)

    guard let maxComparableBalance = Decimal.PIPComparableBalance(from: selectedBalance),
          let coinFromId = self.dependency.coinService.coinId(symbol: fromCoin),
          let coinToId = self.dependency.coinService.coinId(symbol: getCoin)
          else {
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

    Observable.zip(
      self.dependency.coinService.estimate(fromCoin: fromCoin, toCoin: getCoin.transformToCoinName(),
                                           amount: value, type: .input),
      self.dependency.poolService.route(from: fromCoin, to: getCoin.transformToCoinName(),
                                        amount: value, type: .input).catchErrorJustReturn(nil)
      ).do(onNext: { [weak self] (_) in
        self?.isApproximatelyLoading.onNext(false)
      }, onError: { [weak self] (error) in
        self?.isApproximatelyLoading.onNext(false)
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
      }, onSubscribe: { [weak self] in
        self?.isApproximatelyLoading.onNext(true)
        self?.isPoolExhange.accept(false)
        self?.poolPath.accept([])
      }).subscribe(onNext: { [weak self] (res) in
        let estiamte = res.0
        let pool = res.1
        
        if let route = pool {
          self?.isPoolExhange.accept((route.type == "pool"))
          self?.poolPath.accept(route.route.compactMap {$0.id})
        } else {
          self?.isPoolExhange.accept(false)
        }

        let val = estiamte?.amountOut ?? 0.0

        let appr = (CurrencyNumberFormatter.coinFormatter.formattedDecimal(with: val > 0 ? val : 0)) + " " + getCoin
        self?.approximately.onNext(appr)

        var approximatelyRoundedVal = (val * 0.95)
//        approximatelyRoundedVal.round(.up)
        self?.minimumValueToBuy.accept(approximatelyRoundedVal)

        let gtCoin = try? self?.getCoin.value() ?? ""
        if getCoin.transformToCoinName() == gtCoin?.transformToCoinName() {
          self?.approximatelyReady.onNext(true)
        }
      }).disposed(by: disposeBag)
  }

  override func validateErrors() {
    if let amountString = self.spendAmount.value, let amount = Decimal(string: amountString) {
      if amount > selectedBalance {
        let isMax = Decimal.PIPComparableBalance(from: self.selectedBalance) == Decimal.PIPComparableBalance(from: amount)
        if !isMax {
          amountError.accept("INSUFFICIENT FUNDS".localized())
        }
      } else {
        amountError.accept(nil)
      }
    } else {
      let amountString = self.spendAmount.value
      if nil == amountString || amountString == "" || amountString == "," || amountString == "." {
        amountError.accept(nil)
      } else {
        amountError.accept("INCORRECT AMOUNT".localized())
      }
    }
  }

  func exchange() {

    guard
      let coinFrom = self.selectedCoin?.transformToCoinName(),
      let coinFromId = self.dependency.coinService.coinId(symbol: coinFrom),
      let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
      let coinToId = self.dependency.coinService.coinId(symbol: coinTo),
      let amount = self.spendAmount.value,
      let minimumBuyValue = self.minimumValueToBuy.value
    else {
      return
    }

    Observable<Void>.just(()).flatMap{_ in self.coinService.updateCoinsWithResponse()}.withLatestFrom(dependency.balanceService.account)
      .filter({ (account) -> Bool in
        return account != nil && (account?.address.isValidAddress() ?? false)
    }).map({ (item) -> String in
      return item?.address ?? ""
    }).flatMap { selectedAddress in
      return self.processExchange(coinFromId: coinFromId,
                                  coinToId: coinToId,
                                  amount: amount,
                                  selectedAddress: selectedAddress,
                                  minimumBuyValue: minimumBuyValue)
    }.delay(.seconds(1), scheduler: MainScheduler.instance)
    .flatMap({ [weak self] (hash) -> Observable<MinterExplorer.Transaction?> in
      guard let `self` = self, let hash = hash else { return Observable.error(SpendCoindsViewModelError.incorrectParams) }
      return self.dependency.transactionService.transaction(hash: hash)
        .retry(.exponentialDelayed(maxCount: 3, initial: 1.0, multiplier: 2.0), scheduler: MainScheduler.instance, shouldRetry: nil)
        .do(onError: { [weak self] (error) in
          //If error in getting transaction - show convert succeeed without estimates
          self?.exchangeSucceeded.onNext((message: "Coins have been exchanged".localized(), transactionHash: hash))
          self?.shouldClearForm.accept(true)
          self?.dependency.balanceService.updateBalance()
        })
    }).subscribe(onNext: { [weak self] (transaction) in
      guard let `self` = self else { return }
      if let transactionData = transaction?.data as? MinterExplorer.ConvertTransactionData,
        let coin = transactionData.toCoin?.symbol,
        let amount = transactionData.valueToBuy {
        let string = CurrencyNumberFormatter.formattedDecimal(with: amount, formatter: CurrencyNumberFormatter.coinFormatter) + " " + coin
          self.exchangeSucceeded.onNext((message: string, transactionHash: transaction?.hash))
      } else {
        let string = "Coins have been exchanged".localized()
        self.exchangeSucceeded.onNext((message: string, transactionHash: transaction?.hash))
      }
    }, onError: { [weak self] (error) in
      if error is TransactionServiceError {
        //Show success
      } else {
        self?.handleError(error)
      }
    }, onCompleted: {
      self.shouldClearForm.accept(true)
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

    if let apiError = err as? HTTPClientError {
      var errorCode = -1
      if let eCode = apiError.userData?["code"] as? String {
        errorCode = Int(eCode) ?? -1
      } else if let eCode = apiError.userData?["code"] as? Int {
        errorCode = eCode
      }

      if errorCode == 107 {
        title = "Not enough coins to spend".localized()
      } else if errorCode == 103 {
        title = "Coin reserve balance is not sufficient for transaction".localized()
      } else {
        if let msg = apiError.userData?["message"] as? String {
          title = msg
        } else if let msg = apiError.userData?["log"] as? String {
          title = msg
        } else {
          title = "An error occured".localized()
        }
      }
    }
    self.errorNotification.onNext(title)
  }

  func processExchange(coinFromId: Int,
                       coinToId: Int,
                       amount: String,
                       selectedAddress: String,
                       minimumBuyValue: Decimal) -> Observable<String?> {
    return Observable<String?>.create { [unowned self] observer -> Disposable in

      guard let amnt = Decimal(string: amount),
        let convertVal = BigUInt(decimal: amnt, fromPIP: true),
        convertVal > 0 else {
          observer.onError(SpendCoindsViewModelError.incorrectParams)
          return Disposables.create()
      }

      let isMax = CurrencyNumberFormatter.formattedDecimal(with: self.selectedBalance,
                                                           formatter: self.decimalFormatter, maxPlaces: 18) == amount

      var realAmount = convertVal
      //If is max value - get real value
      if isMax {
        realAmount = BigUInt(decimal: self.selectedBalance, fromPIP: true) ?? convertVal
      }

      DispatchQueue.global(qos: .userInitiated).async {
        guard let pk = self.accountManager.privateKey(for: selectedAddress.stripMinterHexPrefix()) else {
          observer.onError(SpendCoindsViewModelError.noPrivateKey)
          return
        }

        guard let fromCoin = self.dependency.coinService.coinBy(id: coinFromId)?.symbol,
              let toCoin = self.dependency.coinService.coinBy(id: coinToId)?.symbol else {
          return
        }

        let obs: Observable<(Decimal, [Coin])> = self.isPoolExhange.value ? self.dependency.coinService.route(fromCoin: fromCoin, toCoin: toCoin, amount: amnt.decimalFromPIP(), type: "input") : Observable.just((0.0, []))

        Observable.zip(GateManager.shared.nonce(address: selectedAddress),
                       GateManager.shared.minGas(), obs).flatMap({ (val) -> Observable<String?> in
                        
          let coins = val.2.1
                        
          let nonce = Decimal(val.0 + 1)

          var tx: RawTransaction!
          let coinId = self.canPayComissionWithBaseCoin() ? self.baseCoin.id! : coinFromId
          let isBaseCoin = self.baseCoin.id! == coinFromId

          let minValBuy = BigUInt(decimal: minimumBuyValue.decimalFromPIP()) ?? BigUInt(0)

          //Using SellAll TX in case we're using maximum amount or there is no base coin (MNT, BIP) to pay commission
          if isMax && (isBaseCoin || !self.canPayComissionWithBaseCoin()) {
            if coins.count > 0 {
              self.poolPath.accept(coins.compactMap {$0.id})
              tx = SellAllSwapPoolRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                                 gasCoinId: coinId,
                                                 coins: coins.compactMap { $0.id },
                                                 minimumValueToBuy: minValBuy)
            } else {
              tx = SellAllCoinsRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                              gasPrice: val.1,
                                              gasCoinId: coinId,
                                              coinFromId: coinFromId,
                                              coinToId: coinToId,
                                              minimumValueToBuy: minValBuy)
            }
          } else {
            if coins.count > 0 {
              self.poolPath.accept(coins.compactMap {$0.id})
              tx = SellSwapPoolRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                              gasCoinId: coinId,
                                              coins: coins.compactMap { $0.id },
                                              valueToSell: realAmount,
                                              minimumValueToBuy: minValBuy)
            } else {
              tx = SellCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                          gasPrice: val.1,
                                          gasCoinId: coinId,
                                          coinFromId: coinFromId,
                                          coinToId: coinToId,
                                          value: realAmount,
                                          minimumValueToBuy: minValBuy)
            }
          }
          let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk.raw.toHexString())
          return GateManager.shared.send(rawTx: signedTx).map {$0.0}
        }).subscribe(onNext: { [observer] (hash) in
          observer.onNext(hash)
          observer.onCompleted()
        }, onError: { [observer] err in
          observer.onError(err)
        }).disposed(by: self.disposeBag)
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
    dependency.coinService.coins(by: term)
      .subscribe(onNext: { (coins) in
        completion?(coins)
      }).disposed(by: disposeBag)
  }

  private func rawTx(nonce: BigUInt = BigUInt(1),
                     gasPrice: Int = 1,
                     coinFromId: Int,
                     coinToId: Int,
                     amount: Decimal,
                     minimumValueToBuy: Decimal,
                     coins: [Coin]) -> RawTransaction {
    let convertedAmount = BigUInt(decimal: amount, fromPIP: true)

    let isMax = Decimal.PIPComparableBalance(from: self.selectedBalance) == amount

    var realAmount = convertedAmount ?? BigUInt(0)
    //If is max value - get real value
    if isMax {
      realAmount = BigUInt(decimal: self.selectedBalance, fromPIP: true) ?? convertedAmount ?? BigUInt(0)
    }

    var tx: RawTransaction!
    let coinId = self.canPayComissionWithBaseCoin() ? self.baseCoin.id! : coinFromId
    let isBaseCoin = self.baseCoin.id! == coinFromId

    let minValBuy = BigUInt(decimal: minimumValueToBuy) ?? BigUInt(0)

    //Using SellAll TX in case we're using maximum amount or there is no base coin (MNT, BIP) to pay commission
    if isMax && (isBaseCoin || !self.canPayComissionWithBaseCoin()) {
      if coins.count > 0 {
        tx = SellAllSwapPoolRawTransaction(nonce: nonce,
                                           gasCoinId: coinId,
                                           coins: coins.compactMap { $0.id },
                                           minimumValueToBuy: minValBuy)
      } else {
        tx = SellAllCoinsRawTransaction(nonce: nonce,
                                        gasPrice: gasPrice,
                                        gasCoinId: coinId,
                                        coinFromId: coinFromId,
                                        coinToId: coinToId,
                                        minimumValueToBuy: minValBuy)
      }
    } else {
      if coins.count > 0 {
        tx = SellSwapPoolRawTransaction(nonce: nonce,
                                        gasCoinId: coinId,
                                        coins: coins.compactMap { $0.id },
                                        valueToSell: realAmount,
                                        minimumValueToBuy: minValBuy)
      } else {
        tx = SellCoinRawTransaction(nonce: nonce,
                                    gasPrice: gasPrice,
                                    gasCoinId: coinId,
                                    coinFromId: coinFromId,
                                    coinToId: coinToId,
                                    value: realAmount,
                                    minimumValueToBuy: minValBuy)
      }
    }
    return tx
  }

}
