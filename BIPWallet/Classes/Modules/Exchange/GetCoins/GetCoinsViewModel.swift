//
//  GetCoinsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MinterCore
import MinterExplorer
import BigInt

class GetCoinsViewModel: ConvertCoinsViewModel, ViewModel {

  // MARK: -

  private var didTapExchangeButton = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: GetCoinsViewModel.Input!
  var output: GetCoinsViewModel.Output!
  var dependency: GetCoinsViewModel.Dependency!

  struct Input {
    var spendCoin: BehaviorRelay<String?>
    var getCoin: AnyObserver<String?>
    var getAmount: BehaviorRelay<String?>
    var didTapExchangeButton: AnyObserver<Void>
  }

  struct Output {
    var spendCoin: Observable<String?>
    var approximately: Observable<String?>
    var isApproximatelyLoading: Observable<Bool>
    var isButtonEnabled: Observable<Bool>
    var showConfirmation: Observable<(String?, String?)>
  }

  struct Dependency {
    var balanceService: BalanceService
    var coinService: CoinService
    var gateService: GateService
    var transactionService: TransactionService
    var poolService: PoolService
  }

  init(dependency: Dependency) {
    super.init(balanceService: dependency.balanceService,
               coinService: dependency.coinService,
               gateService: dependency.gateService)

    self.input = Input(spendCoin: spendCoin,
                       getCoin: getCoin.asObserver(),
                       getAmount: getAmount,
                       didTapExchangeButton: didTapExchangeButton.asObserver()
    )

    self.output = Output(spendCoin: spendCoinField.asObservable(),
                         approximately: approximately.asObservable(),
                         isApproximatelyLoading: isApproximatelyLoading.asObservable(),
                         isButtonEnabled: isButtonEnabled,
                         showConfirmation: showConfirmation.asObservable()
    )

    self.dependency = dependency

    bind()
  }

  // MARK: -

  private func bind() {
    getAmount.distinctUntilChanged().debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance).map { (val) -> String? in
      return AmountHelper.transformValue(value: val)
    }.subscribe(onNext: { val in
      self.getAmount.accept(val)
    }).disposed(by: disposeBag)

    dependency.balanceService.balances()
      .subscribe(onNext: { [weak self] (val) in
        let balances = val.balances

        var spendCoinSource = [String: Decimal]()
        balances.keys.forEach({ (coin) in
          spendCoinSource[coin] = balances[coin]?.0 ?? 0.0
        })

        self?.spendCoinPickerSource = spendCoinSource

        if self?.selectedCoin != nil {
          self?.spendCoinField.onNext(self?.spendCoinText)
          self?.spendCoin.accept(self?.spendCoinText)
        }
      }).disposed(by: disposeBag)

    let formObservable = Observable.combineLatest(getCoin.asObservable(),
                                                  getAmount.asObservable(),
                                                  spendCoin.asObservable())

    formObservable.debounce(.milliseconds(500), scheduler: MainScheduler.instance)
    .filter({ (val) -> Bool in
      return CoinValidator.isValid(coin: val.2)
    }).distinctUntilChanged({ (val1, val2) -> Bool in
      return (val1.0 ?? "") == (val2.0 ?? "") && (val1.1 ?? "") == (val2.1 ?? "") && (val1.2 ?? "") == (val2.2 ?? "")
    }).subscribe(onNext: { [weak self] (val) in
      self?.approximatelySum.onNext(nil)
      self?.approximately.onNext("")
      self?.calculateApproximately()
      self?.checkAmountValue()
    }).disposed(by: disposeBag)

    shouldClearForm.asObservable().subscribe(onNext: { [weak self] (_) in
      self?.getAmount.accept(nil)
      self?.getCoin.onNext("")
      self?.validateErrors()
    }).disposed(by: disposeBag)

    didTapExchangeButton.withLatestFrom(self.approximately)
      .subscribe(onNext: { [weak self] (val) in
        let approx = val
        guard
          let `self` = self,
          let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
          let amount = self.getAmount.value else { return }

        let toString = CurrencyNumberFormatter.formattedDecimal(with: Decimal(string: amount) ?? 0.0, formatter: self.formatter) + " " + coinTo
        let fromString = approx

        self.showConfirmation.onNext((fromString, toString))
      }).disposed(by: disposeBag)

    spendCoin.distinctUntilChanged()
      .map({ (val) -> SpendCoinPickerItem? in
        let item = SpendCoinPickerItem.items(with: self.spendCoinPickerSource).filter({ (item) -> Bool in
          return item.title == val
        }).first
        return item
      }).filter({ (item) -> Bool in
        return item != nil
      }).subscribe(onNext: { [weak self] (item) in
        self?.selectedCoin = item?.coin
        self?.spendCoin.accept(item?.coin)
      }).disposed(by: disposeBag)
    
    let estim = estimate.share()
    
    estim.map { [weak self] estimate in
      var approximatelyValue: String = ""
      switch estimate {
      case .bancor(let val):
        approximatelyValue = (self?.formatter.formattedDecimal(with: val) ?? "") + " " + (self?.spendCoin.value ?? "")
      
      default:
        approximatelyValue = "OLOLO"
//      break
//        approximatelyValue = (self?.formatter.formattedDecimal(with: val > 0 ? val : 0) ?? "") + " " + //from
      }
      return approximatelyValue
    }.subscribe(approximately).disposed(by: disposeBag)

    estim.map { estimate in
      return true
    }.subscribe(approximatelyReady).disposed(by: disposeBag)

  }

  enum Estimate {
    case pool(route: [Coin], estimate: Decimal)
    case bancor(estimate: Decimal)
  }

  private var estimate = PublishSubject<Estimate>()

  private var spendCoin = BehaviorRelay<String?>(value: nil)
  //TODO: Move to parent as amount
  private var getAmount = BehaviorRelay<String?>(value: nil)
  var approximately = PublishSubject<String?>()
  var approximatelySum = BehaviorSubject<Decimal?>(value: nil)
  var isButtonEnabled: Observable<Bool> {
    return Observable.combineLatest(getCoin.asObservable(),
                                    approximatelySum.asObservable(),
                                    hasCoin.asObservable(),
                                    isLoading.asObservable()
                                    )
      .map({ (val) -> Bool in
        guard !val.3 else {
          return false
        }

        if (self.selectedCoin ?? "") == (val.0 ?? "") {
          return false
        }
        let amnt = (val.1 ?? 0)
        return amnt > 0 && self.hasCoin.value
      })
  }

  // MARK: -

  private func checkAmountValue() {
    if let amountString = self.getAmount.value,
      let amnt = Decimal(str: amountString), amnt > 0 {
      if !AmountValidator.isValid(amount: amnt) {
        self.amountError.accept("TOO SMALL VALUE".localized())
      } else {
        self.amountError.accept("")
      }
    } else {
        self.amountError.accept("")
    }
  }

  func calculateApproximately() {
    approximatelyReady.onNext(false)
    approximatelySum.onNext(nil)
    isPoolExhange.accept(false)
    poolPath.accept([])

    guard let from = selectedCoin?.uppercased(),
      let to = try? self.getCoin.value()?.uppercased() ?? "",
      let amountString = self.getAmount.value,
      let amnt = Decimal(str: amountString), amnt > 0
        && (amnt > 1.0/TransactionCoinFactorDecimal) && CoinValidator.isValid(coin: to) && CoinValidator.isValid(coin: from) else {
      return
    }

    isApproximatelyLoading.onNext(true)

    Observable.zip(
      self.dependency.coinService.estimate(fromCoin: from, toCoin: to.transformToCoinName(),
                                           amount: amnt.decimalFromPIP(), type: .output),
      self.dependency.poolService.route(from: from, to: to, amount: amnt.decimalFromPIP(), type: .output).catchErrorJustReturn(nil),
      self.dependency.gateService.commission()
    )
    .do(onError: { [weak self] _ in
      self?.isApproximatelyLoading.onNext(false)
    }, onCompleted: { [weak self] in
      self?.isApproximatelyLoading.onNext(false)
    }, onSubscribe: { [weak self] in
      self?.isApproximatelyLoading.onNext(true)
    })
    /*.map({ response in
      let isPool = response.1?.type == "pool"
      var route: [Coin]?
      if isPool {
        route = response.1?.route.compactMap {$0}
//        normalizedCommission = canPayComissionWithBaseCoin ? 0 : res.0.commission.PIPToDecimal()
      } else {
//        self?.poolPath.accept([])
//        normalizedCommission = canPayComissionWithBaseCoin ? 0 : res.0.commission.PIPToDecimal()
      }
      return isPool ? Estimate.pool(route: route ?? [], estimate: response.1?.amountOut ?? 0.0)
        : Estimate.bancor(estimate: response.0.commission)
    })*/
  .subscribe(onNext: { [weak self] res in
    let estiamte = res.0
    let commissions = res.2
//      if let route = res.1 {
        self?.isPoolExhange.accept((estiamte?.swapType == "pool"))
//      } else {
//        self?.isPoolExhange.accept(false)
//      }

      //if we can pay commission with base coin - set normalized comission to zero
      let canPayComissionWithBaseCoin = (self?.canPayComissionWithBaseCoin() ?? false)

      var normalizedCommission: Decimal

      if self?.isPoolExhange.value == true {
        let path = res.1?.route.compactMap {$0.id} ?? []
        self?.poolPath.accept(path)
        let additionalFee = path.count > 2 ? Decimal(path.count - 2) * (commissions.transactionCommissions[.buyPoolBase]?.PIPToDecimal() ?? 0) : 0.0
        normalizedCommission = canPayComissionWithBaseCoin ? 0 : additionalFee
      } else {
        self?.poolPath.accept([])
//        normalizedCommission = canPayComissionWithBaseCoin ? 0 : res.0.commission.PIPToDecimal()
        normalizedCommission = canPayComissionWithBaseCoin ? 0 : commissions.transactionCommissions[.buyBancor]?.PIPToDecimal() ?? 0
      }

    let val = (estiamte?.amountIn ?? 0) + normalizedCommission

      let approximatelyValue = (self?.formatter.formattedDecimal(with: val > 0 ? val : 0) ?? "") + " " + from
      self?.approximately.onNext(approximatelyValue)
      self?.approximatelySum.onNext(val)
      self?.isApproximatelyLoading.onNext(false)
      self?.approximatelyReady.onNext(true)
    }, onError: { [weak self] error in
      self?.approximatelyReady.onNext(false)
      if let err = error as? HTTPClientError {
        var logMes = "Estimate can't be calculated at the moment".localized()
        if let log = (err.userData?["log"] as? String ?? err.userData?["message"] as? String) {
          logMes = log
        }
        self?.approximately.onNext(logMes)
        return
      }
      self?.approximately.onNext("Estimate can't be calculated at the moment".localized())
    }).disposed(by: self.disposeBag)

    /*GateManager.shared.estimateCoinBuy(coinFrom: from,
                                       coinTo: to,
                                       value: amnt * TransactionCoinFactorDecimal) { [weak self] (val, commission, type, error) in

      self?.isApproximatelyLoading.onNext(false)

      guard nil == error,
        let ammnt = val,
        let commission = commission else {

        if let err = error as? HTTPClientError {
          var logMes = "Estimate can't be calculated at the moment".localized()
          if let log = (err.userData?["log"] as? String ?? err.userData?["message"] as? String) {
            logMes = log
          }
          self?.approximately.onNext(logMes)
          return
        }

        self?.approximately.onNext("Estimate can't be calculated at the moment".localized())
        return
      }

      //if we can pay commission with base coin - set normalized comission to zero
      let canPayComissionWithBaseCoin = (self?.canPayComissionWithBaseCoin() ?? false)
      let normalizedCommission = canPayComissionWithBaseCoin ? 0 : commission / TransactionCoinFactorDecimal
      let val = (ammnt / TransactionCoinFactorDecimal) + normalizedCommission

      let approximatelyValue = (self?.formatter.formattedDecimal(with: val > 0 ? val : 0) ?? "") + " " + from
      self?.approximately.onNext(approximatelyValue)
      self?.isPoolExhange.accept((type == "pool"))

      self?.approximatelySum.onNext(val)

      if to == (try? self?.getCoin.value() ?? "") {
        if self?.isPoolExhange.value == true {
          self?.dependency.coinService.route(fromCoin: from,
                                            toCoin: to,
                                            amount: amnt * TransactionCoinFactorDecimal,
                                            type: "output")
            .subscribe(onNext: { res in
              self?.poolPath.accept(res.1.compactMap {$0.id})
              self?.approximatelyReady.accept(true)
            }, onError: { error in
              self?.approximatelyReady.accept(true)
            }).disposed(by: self!.disposeBag)
        } else {
          self?.approximatelyReady.accept(true)
        }
      }
    }*/
  }

  func exchange(selectedAddress: String) {
    var approximatelySumRoundedVal = ((try? self.approximatelySum.value()) ?? 0) * 1.05 * TransactionCoinFactorDecimal
    approximatelySumRoundedVal.round(.up)
    guard
      let coinFrom = self.selectedCoin?.transformToCoinName(),
      let coinFromId = self.dependency.coinService.coinId(symbol: coinFrom),
      let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
      let coinToId = self.dependency.coinService.coinId(symbol: coinTo),
      let amntString = self.getAmount.value, let amount = Decimal(str: amntString),
      let maximumValueToSell = BigUInt(decimal: approximatelySumRoundedVal)
      else {
        self.errorNotification.onNext("Incorrect amount".localized())
        return
    }

    let ammnt = amount * TransactionCoinFactorDecimal

    let convertVal = (BigUInt(decimal: ammnt) ?? BigUInt(0))

    let value = convertVal

    if value <= 0 {
      return
    }

    isLoading.onNext(true)

    DispatchQueue.global(qos: .userInitiated).async {
      guard let mnemonic = self.accountManager.mnemonic(for: selectedAddress.stripMinterHexPrefix()),
        let seed = self.accountManager.seed(mnemonic: mnemonic),
        let privateKey = try? self.accountManager.privateKey(from: seed).raw.toHexString() else {
        self.isLoading.onNext(false)
        //Error no Private key found
        assert(true)
        self.errorNotification.onNext("No private key found".localized())
        return
      }

      GateManager.shared.nonce(for: selectedAddress, completion: { [weak self] (count, err) in

        GateManager.shared.minGasPrice(completion: { (gasPrice, _) in

          guard err == nil, let nnce = count else {
            self?.isLoading.onNext(false)
            self?.errorNotification.onNext("Can't get nonce")
            return
          }

          let gas = gasPrice ?? RawTransactionDefaultGasPrice

          let nonce = nnce + 1

          let coin = (self?.canPayComissionWithBaseCoin() ?? false) ? Coin.baseCoin().id : coinFromId
          guard let coinId = coin else {
            self?.errorNotification.onNext("Can't find coin with id \(coinFromId)")
            return
          }

          self?.buyRawTransaction(nonce: nonce,
                                  gasPrice: gas,
                                  gasCoinId: coinId,
                                  coinFromId: coinFromId,
                                  coinToId: coinToId,
                                  value: value,
                                  maximumValueToSell: maximumValueToSell,
                                  completion: { rawTx in
                                    guard let rawTx = rawTx else { return }
                                    let signedTx = RawTransactionSigner.sign(rawTx: rawTx, privateKey: privateKey)

                                    GateManager.shared.sendRawTransaction(rawTransaction: signedTx!, completion: { (hash, block, err) in

                                      self?.isLoading.onNext(false)

                                      defer {
                                        self?.dependency.balanceService.updateBalance()
                                      }

                                      guard let `self` = self else { return }

                                      guard nil == err else {
                                        self.handleError(err)
                                        return
                                      }

                                      self.shouldClearForm.accept(true)

                                      if let hash = hash {
                                        self.dependency.transactionService.transaction(hash: hash)
                                          .delay(.seconds(1), scheduler: MainScheduler.instance)
                                          .retry(.exponentialDelayed(maxCount: 3, initial: 1.0, multiplier: 2.0), scheduler: MainScheduler.instance, shouldRetry: nil)
                                          .subscribe(onNext: { [weak self] (transaction) in
                                            guard let `self` = self else { return }
                                            if let transactionData = transaction?.data as? MinterExplorer.ConvertTransactionData,
                                              let coin = transactionData.toCoin?.symbol,
                                              let amount = transactionData.valueToBuy {
                                              let string = CurrencyNumberFormatter.formattedDecimal(with: amount, formatter: self.formatter) + " " + coin
                                                self.exchangeSucceeded.onNext((message: string, transactionHash: transaction?.hash))
                                            } else {
                                              let string = "Coins have been exchanged".localized()
                                              self.exchangeSucceeded.onNext((message: string, transactionHash: transaction?.hash))
                                            }
                                          }, onError: { error in
                                            //If error in getting transaction - show convert succeeed without estimates
                                            self.exchangeSucceeded.onNext((message: "Coins have been exchanged".localized(), transactionHash: hash))
                                        }).disposed(by: self.disposeBag)
                                      } else {
                                        self.errorNotification.onNext("An error occured".localized())
                                      }
                                    })
                                  })
        })
      })
    }
  }

  private func handleError(_ err: Error?) {
    if
      let apiError = err as? HTTPClientError,
      let errorCode = apiError.userData?["code"] as? Int {
      if errorCode == 107 {
        self.errorNotification.onNext("Not enough coins to spend".localized())
      } else if errorCode == 103 {
        self.errorNotification.onNext("Coin reserve balance is not sufficient for transaction".localized())
      } else {
        if let msg = apiError.userData?["log"] as? String {
          self.errorNotification.onNext(msg)
        } else {
          self.errorNotification.onNext("An error occured".localized())
        }
      }
      return
    }
    self.errorNotification.onNext("Can't send Transaction")
  }

  override func coins(by term: String, completion: (([Coin]) -> ())?) {
    dependency.coinService.coins(by: term)
      .subscribe(onNext: { (coins) in
        completion?(coins)
      }).disposed(by: disposeBag)
  }

  private func buyRawTransaction(nonce: Decimal,
                                 gasPrice: Int,
                                 gasCoinId: Int,
                                 coinFromId: Int,
                                 coinToId: Int,
                                 value: BigUInt,
                                 maximumValueToSell: BigUInt,
                                 completion: ((RawTransaction?) -> ())?) {
    if (!self.isPoolExhange.value) {
      // TODO: remove after https://github.com/MinterTeam/minter-go-node/issues/224
      let maxValueToSell = maximumValueToSell

      let rawTx = BuyCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                        gasPrice: gasPrice,
                                        gasCoinId: gasCoinId,
                                        coinFromId: coinFromId,
                                        coinToId: coinToId,
                                        value: value,
                                        maximumValueToSell: maxValueToSell)
      completion?(rawTx)
    } else {
      guard let coinFrom = self.dependency.coinService.coinBy(id: coinFromId),
            let coinTo = self.dependency.coinService.coinBy(id: coinToId) else {
        completion?(nil)
        return
      }
      self.dependency.coinService.route(fromCoin: coinFrom.symbol ?? "",
                                        toCoin: coinTo.symbol ?? "",
                                        amount: Decimal(bigInt: value) ?? 0.0, type: "output")
        .subscribe(onNext: { res in
          self.poolPath.accept(res.1.compactMap {$0.id})
          let tx = BuySwapPoolRawTransaction(nonce: BigUInt(decimal: nonce)!, gasCoinId: gasCoinId, coins: res.1.compactMap {$0.id}, valueToBuy: value, maximumValueToSell: maximumValueToSell)
          completion?(tx)
        }, onError: { err in
          completion?(nil)
        }).disposed(by: disposeBag)
    }
  }
  
  private func buyRawTransaction(nonce: Decimal,
                                 gasPrice: Int,
                                 gasCoinId: Int,
                                 coinFromId: Int,
                                 coinToId: Int,
                                 value: BigUInt,
                                 maximumValueToSell: BigUInt,
                                 path: [Coin] = []) -> RawTransaction? {
    if (path.count == 0) {
      let maxValueToSell = maximumValueToSell

      let rawTx = BuyCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                        gasPrice: gasPrice,
                                        gasCoinId: gasCoinId,
                                        coinFromId: coinFromId,
                                        coinToId: coinToId,
                                        value: value,
                                        maximumValueToSell: maxValueToSell)
      return rawTx
    } else {
      guard let coinFrom = self.dependency.coinService.coinBy(id: coinFromId),
            let coinTo = self.dependency.coinService.coinBy(id: coinToId) else {
        return nil
      }
      return BuySwapPoolRawTransaction(nonce: BigUInt(decimal: nonce)!, gasCoinId: gasCoinId, coins: path.compactMap {$0.id}, valueToBuy: value, maximumValueToSell: maximumValueToSell)
    }
  }
  
  func gasCoinId(coinFromId: Int) -> Int? {
    return self.canPayComissionWithBaseCoin() ? self.dependency.gateService.lastComission?.coin?.id : coinFromId
  }

}
