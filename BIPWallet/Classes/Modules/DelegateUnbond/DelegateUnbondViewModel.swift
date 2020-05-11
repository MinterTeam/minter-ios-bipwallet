//
//  DelegateUnbondViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt
import MinterCore
import MinterExplorer
import RxSwiftExt

enum DelegateUnbondViewModelError: Error {
  case noPrivateKey
  case cantSignTransaction
  case noAccount
  case insufficientFunds
  case cantGetEstimate
}

class DelegateUnbondViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  private(set) var maxUnbondAmount: Decimal?
  private(set) var isUnbond = false
  private(set) var validator: ValidatorItem?

  private var balances: [String: Decimal] = [:]
  private var validators: [String: Decimal] = [:]
  private var coinsPickerSource: [String: SpendCoinPickerItem] = [:]
  private var validatorsPickerSource: [String: ValidatorItem] = [:]
  private let coin = BehaviorRelay<String?>(value: "")
  private let amount = BehaviorRelay<String?>(value: "")
  private let isLoading = BehaviorSubject<Bool>(value: false)
  private let didTapValidator = PublishSubject<Void>()
  private let didTapCoin = PublishSubject<Void>()
  private let successMessage = PublishSubject<String>()
  private let errorMessage = PublishSubject<String>()

  lazy private var form = Observable.combineLatest(coin, didSelectValidator, amount).map { (val) -> (String?, ValidatorItem?, Decimal?) in
    let publicKey = val.1
    var coin: String?

    var validator: ValidatorItem?
    if let firstValue = publicKey.first?.value, let firstItem = self.validatorsPickerSource[firstValue] {
      validator = firstItem
    }
    if let coinKey = val.0 {
      coin = self.coinsPickerSource[coinKey]?.coin
    }
    if self.isUnbond {
      coin = val.0
    }
    var amount = Decimal(string: val.2 ?? "")
    return (coin, validator, amount)
  }.share()

  private var isButtonEnabled: Observable<Bool> {
    return Observable.merge(isValidForm, isLoading).withLatestFrom(Observable.combineLatest(isValidForm, isLoading)) { first, val -> Bool in
      let (form, isLoading) = val
      return form && !isLoading
    }
  }

  private var isValidForm: Observable<Bool> {
    return form.map { (val) -> Bool in
      let (coin, validator, amount) = val
      return coin != nil && (validator?.publicKey.isValidPublicKey() ?? false) && amount != nil
    }.share()
  }
  private let didSelectValidator = PublishSubject<[Int: String]>()
  private let didSelectCoin = PublishSubject<[Int: String]>()
  private let validatorName = PublishSubject<String>()
  private let validatorPublicKey = PublishSubject<String>()
  private let didTapSend = PublishSubject<Void>()
  private let didTapUseMax = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: DelegateUnbondViewModel.Input!
  var output: DelegateUnbondViewModel.Output!
  var dependency: DelegateUnbondViewModel.Dependency!

  struct Input {
    var coin: BehaviorRelay<String?>
    var amount: BehaviorRelay<String?>
    var didTapValidator: AnyObserver<Void>
    var didTapCoin: AnyObserver<Void>
    var didSelectValidator: AnyObserver<[Int: String]>
    var didSelectCoin: AnyObserver<[Int: String]>
    var didTapSend: AnyObserver<Void>
    var didTapUseMax: AnyObserver<Void>
  }

  struct Output {
    var validatorName: Observable<String>
    var validatorPublicKey: Observable<String>
    var showValidators: Observable<[[String]]>
    var showCoins: Observable<[[String]]>
    var isLoading: Observable<Bool>
    var isButtonEnabled: Observable<Bool>
    var buttonTitle: Observable<String?>
    var title: Observable<String?>
    var description: Observable<String?>
    var successMessage: Observable<String>
    var errorMessage: Observable<String>
    var fee: Observable<String>
  }

  struct Dependency {
    var validatorService: ValidatorService
    var balanceService: BalanceService
    var gateService: GateService
    var accountService: AccountService
  }

  init(validator: ValidatorItem? = nil, coinName: String? = nil, isUnbond: Bool = false, maxUnbondAmount: Decimal? = nil, dependency: Dependency) {
    super.init()

    self.maxUnbondAmount = maxUnbondAmount

    self.dependency = dependency

    self.input = Input(coin: coin,
                       amount: amount,
                       didTapValidator: didTapValidator.asObserver(),
                       didTapCoin: didTapCoin.asObserver(),
                       didSelectValidator: didSelectValidator.asObserver(),
                       didSelectCoin: didSelectCoin.asObserver(),
                       didTapSend: didTapSend.asObserver(),
                       didTapUseMax: didTapUseMax.asObserver()
    )

    self.output = Output(validatorName: validatorName.asObservable(),
                         validatorPublicKey: validatorPublicKey.asObservable(),
                         showValidators: showValidatorsObservable(),
                         showCoins: showCoinsObservable(),
                         isLoading: isLoading,
                         isButtonEnabled: isButtonEnabled,
                         buttonTitle: isLoading.map { val in
                          return val ? "" : isUnbond ? "Unbond".localized() : "Delegate".localized()
                         },
                         title: Observable.just((isUnbond ? "Unbond".localized() : "Delegate".localized())),
                         description: {
                          if isUnbond {
                            return Observable.just("The process will be finalized within ~30 days after the request has been sent.")
                          }
                          return Observable.just("Delegate your coins to validators and receive related regular payments.")
    }(),
                         successMessage: successMessage.asObservable(),
                         errorMessage: errorMessage.asObservable(),
                         fee: self.dependency.gateService.currentGas().map({ (gas) -> String in
                          let comType = self.isUnbond ? RawTransactionType.unbond.commission() : RawTransactionType.delegate.commission()
                          let com = (Decimal(gas) * comType).PIPToDecimal()
                          let fee = CurrencyNumberFormatter.formattedDecimal(with: com,
                                                                             formatter: CurrencyNumberFormatter.decimalFormatter) + " " + (Coin.baseCoin().symbol ?? "")
                          
                          return fee
                         })
    )

    self.isUnbond = isUnbond
    self.validator = validator
    self.coin.accept(coinName)

    bind()
  }

  // MARK: -

  func showValidatorsObservable() -> Observable<[[String]]> {
    return didTapValidator.withLatestFrom(self.dependency.validatorService.validators()).map({ (items) -> [[String]] in
      return [items.map { (item) -> String in
        return self.pickerTitle(from: item)
      }]
    })
  }

  func showCoinsObservable() -> Observable<[[String]]> {
    return didTapCoin.filter({ (_) -> Bool in
      return !self.isUnbond
    }).map { (_) -> [[String]] in
      return [self.coinsPickerSource.values.map { (item) -> String in
        return item.title ?? ""
      }]
    }
  }

  func currentCommission() -> Decimal {
    return RawTransactionType.delegate.commission().PIPToDecimal()
  }

  func bind() {

    amount.distinctUntilChanged().debounce(.seconds(1), scheduler: MainScheduler.instance).map { (val) -> String? in
      return AmountHelper.transformValue(value: val)
    }.subscribe(onNext: { val in
      self.amount.accept(val)
    }).disposed(by: disposeBag)

    didTapUseMax.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).withLatestFrom(coin).subscribe(onNext: { (coin) in
      var amount: String?
      if self.isUnbond {
        guard let coin = coin, let balance = self.maxUnbondAmount else { return }
        amount = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: self.coinFormatter)
      } else {
        guard let coin = coin, let balance = self.coinsPickerSource[coin]?.balance else { return }
        amount = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: self.coinFormatter)
      }
      self.amount.accept(amount)
    }).disposed(by: disposeBag)

    self.dependency.validatorService.validators().subscribe(onNext: { (items) in
      items.forEach({ (item) in
        self.validatorsPickerSource[self.pickerTitle(from: item)] = item
      })
      if let validator = self.validator {
        let title = self.pickerTitle(from: validator)
        self.didSelectValidator.onNext([0: title])
      }
    }).disposed(by: disposeBag)

    self.dependency.balanceService.balances().subscribe(onNext: { (val) in
      self.balances = val.balances.mapValues({ (balance) -> Decimal in
        return balance.0
      })

      self.coinsPickerSource = [:]
      val.balances.keys.forEach { (coin) -> Void in
        let item = SpendCoinPickerItem(coin: coin, balance: val.balances[coin]?.0 ?? 0.0)
        guard let title = item.title else { return }

        self.coinsPickerSource[title] = item
        
        //If unbond - don't change coin name on default
        if !self.isUnbond && coin == Coin.baseCoin().symbol {
          self.coin.accept(title)
        }
      }
    }).disposed(by: disposeBag)

    didSelectValidator.subscribe(onNext: { [weak self] (selection) in
      guard let `self` = self else { return }
      if let firstValue = selection.first?.value, let firstItem = self.validatorsPickerSource[firstValue] {
        self.validatorPublicKey.onNext(TransactionTitleHelper.title(from: firstItem.publicKey))
        self.validatorName.onNext(firstItem.name ?? "Public Key".localized())
      }
    }).disposed(by: disposeBag)

    didSelectCoin.subscribe(onNext: { (val) in
      guard let selectedCoin = val.values.first, let selectedItem = self.coinsPickerSource[selectedCoin] else {
        return
      }
      self.coin.accept(selectedItem.title)
    }).disposed(by: disposeBag)

    didTapSend.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.hard)
      self?.sound.onNext(.bip)
    }).withLatestFrom(self.isValidForm).filter { $0 == true }
      .withLatestFrom(Observable.combineLatest(self.form, self.dependency.balanceService.account))
      .do(onNext: { [weak self] (_) in
        self?.isLoading.onNext(true)
      })
      .flatMap { [weak self] (val) -> Observable<RawTransaction> in
        guard let `self` = self,
          let coin = val.0.0,
          let publicKey = val.0.1,
          let amount = val.0.2,
          let aPublicKey = PublicKey(publicKey.publicKey),
          let account = val.1 else { return Observable.empty() }

        let baseCoinBalance = (self.balances[Coin.baseCoin().symbol!] ?? 0.0)
        let coinBalance = (self.balances[coin] ?? 0.0)
        //Update amount if needed
        var newAmount = amount
        var gasCoin = coin
        
        //In unbond - send tx as is
        if self.isUnbond {
          //Gas coin here - MNT
          gasCoin = Coin.baseCoin().symbol!
          return self.makeTransaction(account: account, gasCoin: gasCoin, publicKey: aPublicKey, coin: coin, amount: newAmount)
        }

        if coin == Coin.baseCoin().symbol! {
          //check if can pay comission
          let amountWithCommission = amount + self.currentCommission()
          if baseCoinBalance > amountWithCommission {
            //all good - send tx
          } else {
            //check if USE MAX
            newAmount = amount - self.currentCommission()
            //IF yes - subtract commission
            //else  - error
          }
        } else {
          //check if can pay with baseCoin
          if baseCoinBalance > self.currentCommission() {
            //all good - send tx
            gasCoin = Coin.baseCoin().symbol!
          } else {
            //else - send estimate request and subtract commission from amount
            return self.makeTransactionWithCommission(account: account, gasCoin: gasCoin, publicKey: aPublicKey, coin: coin, amount: amount)
          }
        }
        return self.makeTransaction(account: account, gasCoin: gasCoin, publicKey: aPublicKey, coin: coin, amount: newAmount)
    }.flatMap { [weak self] (transaction) -> Observable<Event<String>> in
      guard let `self` = self else { return Observable.empty() }
      return self.signTransaction(rawTransaction: transaction).materialize()
    }
    .flatMap({ [weak self] (transaction) -> Observable<Event<String?>> in
      guard let `self` = self else { return Observable.empty() }
      switch transaction {
      case .error(let error):
        return Observable.error(error).materialize()

      case .completed:
        return Observable.never().materialize()

      case .next(let signedTx):
        return self.dependency.gateService.send(rawTx: signedTx).materialize()
      }
    })
    .do(onNext: { (_) in
      self.isLoading.onNext(false)
    })
    .subscribe(onNext: { [weak self] val in
      switch val {
      case .completed:
        return

      case .next(let hash):
        if self?.isUnbond ?? false {
          self?.successMessage.onNext("Coins have been successfully unbonded".localized())
        } else {
          self?.successMessage.onNext("Coins have been successfully delegated".localized())
        }
        self?.clearForm()

      case .error(let error):
        self?.handleError(error)
      }
    }).disposed(by: disposeBag)
  }

  func pickerTitle(from item: ValidatorItem) -> String {
    let publicKey = TransactionTitleHelper.title(from: item.publicKey)
    var validatorTitle = publicKey
    if let name = item.name {
      validatorTitle = name + " " + publicKey
    }
    return validatorTitle
  }

  func clearForm() {
    self.amount.accept(nil)
  }

  func handleError(_ error: Error) {
    var errorTitle = "An error occured".localized()
    if let delegateError = error as? DelegateUnbondViewModelError {
      switch delegateError {
      case .cantSignTransaction:
        errorTitle = "Can't sign transaction".localized()
      case .noAccount:
        errorTitle = "No account found".localized()
      case .noPrivateKey:
        errorTitle = "No private key found".localized()
      case .insufficientFunds:
          errorTitle = "Insufficient funds for current transaction".localized()
      case .cantGetEstimate:
        errorTitle = "Can't calculate commission at the moment".localized()
      }
    } else if let apiError = error as? HTTPClientError {
      if let errorMessage = apiError.message {
        errorTitle = errorMessage
      } else if let errorMessage = apiError.userData?["log"] as? String {
        errorTitle = errorMessage
      }
    }
    self.errorMessage.onNext(errorTitle)
  }

}

extension DelegateUnbondViewModel {

  func makeTransactionWithCommission(account: AccountItem, gasCoin: String,
                       publicKey: PublicKey, coin: String, amount: Decimal) -> Observable<RawTransaction> {

    return self.makeTransaction(account: account,
                                gasCoin: gasCoin,
                                publicKey: publicKey,
                                coin: coin,
                                amount: amount)
      .flatMap { transaction -> Observable<Event<Decimal>> in
        let rawTx = transaction.encode()?.toHexString() ?? ""
        return self.dependency.gateService.estimateComission(rawTx: rawTx).materialize()
      }.flatMap { (event) -> Observable<RawTransaction> in
        switch event {
        case .next(let commission):
          //TODO: remove PIPToDecimal and migrate to a newer gateService
          let newAmount = amount - commission.PIPToDecimal()
          if newAmount > 0 {
            return self.makeTransaction(account: account, gasCoin: coin, publicKey: publicKey, coin: coin, amount: newAmount)
          }
          return Observable.error(DelegateUnbondViewModelError.insufficientFunds)
        case .completed:
          break
        default:
          return Observable.error(DelegateUnbondViewModelError.cantGetEstimate)
        }
        return Observable.never()
      }
  }

  func makeTransaction(account: AccountItem, gasCoin: String, publicKey: PublicKey, coin: String, amount: Decimal) -> Observable<RawTransaction> {
    return self.dependency.gateService.nonce(address: account.address).flatMap { nonce in
      return Observable.create { (observer) -> Disposable in
        if self.isUnbond {
          let transaction = UnbondRawTransaction(nonce: BigUInt(nonce+1),
                                                 gasCoin: gasCoin,
                                                 publicKey: publicKey.stringValue,
                                                 coin: coin,
                                                 value: BigUInt(decimal: amount, fromPIP: true) ?? BigUInt(0))
          observer.onNext(transaction)
        } else {
          let transaction = DelegateRawTransaction(nonce: BigUInt(nonce+1),
                                                   gasCoin: gasCoin,
                                                   publicKey: publicKey.stringValue,
                                                   coin: coin,
                                                   value: BigUInt(decimal: amount, fromPIP: true) ?? BigUInt(0))
          observer.onNext(transaction)
        }
        return Disposables.create()
      }
    }
  }

  func signTransaction(rawTransaction: RawTransaction) -> Observable<String> {
    return Observable<Void>.just(Void()).withLatestFrom(self.dependency.balanceService.account).flatMap { (account) -> Observable<String> in
      guard let account = account else { return Observable.error(DelegateUnbondViewModelError.noAccount) }

      return Observable<String>.create { (observer) -> Disposable in
        DispatchQueue.global(qos: .default).async {
          guard let privateKey = self.dependency.accountService.privateKey(for: account) else {
            observer.onError(DelegateUnbondViewModelError.noPrivateKey)
            return
          }

          let signed = RawTransactionSigner.sign(rawTx: rawTransaction, privateKey: privateKey.raw.toHexString())
          DispatchQueue.main.async {
            if signed != nil {
              observer.onNext(signed ?? "")
            } else {
              observer.onError(DelegateUnbondViewModelError.cantSignTransaction)
            }
          }
        }
        return Disposables.create()
      }
    }
  }

}
