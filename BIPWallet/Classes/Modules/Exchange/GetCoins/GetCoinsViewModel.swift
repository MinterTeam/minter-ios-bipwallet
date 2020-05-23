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
    getAmount.distinctUntilChanged()
      .debounce(.seconds(1), scheduler: MainScheduler.instance)
      .map { (val) -> String? in
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

    Observable.combineLatest(getCoin.asObservable(),
                             getAmount.asObservable(),
                             spendCoin.asObservable())
    .debounce(.seconds(1), scheduler: MainScheduler.instance)
    .filter({ (val) -> Bool in
      return CoinValidator.isValid(coin: val.2)
    })
    .subscribe(onNext: { [weak self] (val) in
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
  }

  private var spendCoin = BehaviorRelay<String?>(value: nil)
  //TODO: Move to parent as amount
  private var getAmount = BehaviorRelay<String?>(value: nil)
  var isApproximatelyLoading = PublishSubject<Bool>()
  var approximately = PublishSubject<String?>()
  var approximatelySum = BehaviorSubject<Decimal?>(value: nil)
  var approximatelyReady = PublishSubject<Bool>()
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
        self.amountError.value = "TOO SMALL VALUE".localized()
      } else {
        self.amountError.value = ""
      }
    } else {
      self.amountError.value = ""
    }
  }

  func calculateApproximately() {
    approximatelyReady.onNext(false)
    approximatelySum.onNext(nil)

    guard let from = selectedCoin?.uppercased(),
      let to = try? self.getCoin.value()?.uppercased() ?? "",
      let amountString = self.getAmount.value,
      let amnt = Decimal(str: amountString), amnt > 0
        && (amnt > 1.0/TransactionCoinFactorDecimal) && CoinValidator.isValid(coin: to) && CoinValidator.isValid(coin: from) else {
      return
    }

    isApproximatelyLoading.onNext(true)

    GateManager.shared.estimateCoinBuy(coinFrom: from,
                                       coinTo: to,
                                       value: amnt * TransactionCoinFactorDecimal) { [weak self] (val, commission, error) in

      self?.isApproximatelyLoading.onNext(false)

      guard nil == error,
        let ammnt = val,
        let commission = commission else {

        if let err = error as? HTTPClientError,
          let log = err.userData?["log"] as? String {
            self?.approximately.onNext(log)
            return
        }

        self?.approximately.onNext("Estimate can't be calculated at the moment".localized())
        return
      }

      //if we can pay commission with base coin - set normalized comission to zero
      let canPayComissionWithBaseCoin = (self?.canPayComissionWithBaseCoin() ?? false)
      let normalizedCommission = canPayComissionWithBaseCoin ? 0 : commission / TransactionCoinFactorDecimal
      let val = (ammnt / TransactionCoinFactorDecimal) + normalizedCommission

      let approximatelyValue = CurrencyNumberFormatter.formattedDecimal(with: val > 0 ? val : 0 ,
                                                                        formatter: self!.formatter) + " " + from
      self?.approximately.onNext(approximatelyValue)

      self?.approximatelySum.onNext(val)

      if to == (try? self?.getCoin.value() ?? "") {
        self?.approximatelyReady.onNext(true)
      }
    }
  }

  func exchange(selectedAddress: String) {
    var approximatelySumRoundedVal = ((try? self.approximatelySum.value()) ?? 0) * 1.1 * TransactionCoinFactorDecimal
    approximatelySumRoundedVal.round(.up)

    guard let coinFrom = self.selectedCoin?.transformToCoinName(),
      let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
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

          let coin = (self?.canPayComissionWithBaseCoin() ?? false) ? Coin.baseCoin().symbol : coinFrom
          let coinData = coin?.data(using: .utf8)?.setLengthRight(10) ?? Data(repeating: 0, count: 10)
          //TODO: remove after https://github.com/MinterTeam/minter-go-node/issues/224
          let maxValueToSell = BigUInt(decimal: (self?.selectedBalance ?? 0) * TransactionCoinFactorDecimal) ?? BigUInt(0)//maximumValueToSell

          let rawTx = BuyCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
                                            gasPrice: gas,
                                            gasCoin: coinData,
                                            coinFrom: coinFrom,
                                            coinTo: coinTo,
                                            value: value,
                                            maximumValueToSell: maxValueToSell)
          let signedTx = RawTransactionSigner.sign(rawTx: rawTx, privateKey: privateKey)

          GateManager.shared.sendRawTransaction(rawTransaction: signedTx!, completion: { (hash, err) in

            self?.isLoading.onNext(false)

            defer {
              self?.dependency.balanceService.updateBalance()
            }

            guard let `self` = self else { return }

            guard nil == err else {
              self.handleError(err)
              return
            }

            self.shouldClearForm.value = true

            if let hash = hash {
              self.dependency.transactionService.transaction(hash: hash)
                .delay(.seconds(3), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (transaction) in
                  guard let `self` = self else { return }
                  if let transactionData = transaction?.data as? MinterExplorer.ConvertTransactionData,
                    let coin = transactionData.toCoin,
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
    }
  }

  private func handleError(_ err: Error?) {
    if
      let apiError = err as? HTTPClientError,
      let errorCode = apiError.userData?["code"] as? Int {
      if errorCode == 107 {
        self.errorNotification
          .onNext("Not enough coins to spend".localized())
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

}
