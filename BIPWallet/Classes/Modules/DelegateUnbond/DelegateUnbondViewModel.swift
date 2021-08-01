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
import MinterMy
import RxSwiftExt

enum DelegateUnbondViewModelError: Error {
  case noPrivateKey
  case cantSignTransaction
  case noAccount
  case insufficientFunds
  case cantGetEstimate
}

class DelegateUnbondViewModel: BaseViewModel, ViewModel, LastBlockViewable {

  // MARK: -

  struct Autocomplete {
    var autocompleteValidatorsItems = ReplaySubject<[SearchTextFieldItem]>.create(bufferSize: 1)
    var itemsSource: [String: ValidatorItem] = [:]
  }

  class Amount {
    var value = BehaviorRelay<String?>(value: "")
    var isMax = BehaviorRelay<Bool>(value: false)

    let disposeBag = DisposeBag()

    init() {
      bind()
    }

    private func bind() {
      value.distinctUntilChanged()
        .subscribe(onNext: { _ in self.isMax.accept(false) })
        .disposed(by: disposeBag)
    }
  }

  private var autocomplete = Autocomplete()

  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  private(set) var maxUnbondAmounts: [String: Decimal]?
  private(set) var isUnbond = false

  var validator: ValidatorItem? {
    didSet {
      if let validator = validator {
        self.validatorPublicKey.onNext(TransactionTitleHelper.title(from: validator.publicKey))
        self.validatorName.onNext(validator.name ?? TransactionTitleHelper.title(from: validator.publicKey))
        self.validatorSubject.accept(validator.publicKey)
      }
    }
  }
  private var balances: [String: Decimal] = [:]
  private var validators: [String: Decimal] = [:]
  private var coinsPickerSource: [String: SpendCoinPickerItem] = [:]
  private var validatorsPickerSource: [String: ValidatorItem] = [:]
  private let coin = BehaviorRelay<String?>(value: "")
  private let validatorSubject = BehaviorRelay<String?>(value: "")
  private let amount = Amount()
  private let shouldClear = ReplaySubject<Void>.create(bufferSize: 1)
  private let didTapCoin = PublishSubject<Void>()
  private let errorMessage = PublishSubject<String>()
  private let didSelectAutocompleteItem = PublishSubject<SearchTextFieldItem>()
  private let didTapShowValidators = PublishSubject<Void>()
  lazy private var form = Observable.combineLatest(coin, validatorSubject, amount.value).map { (val) -> (String?, ValidatorItem?, Decimal?) in
    let publicKey = val.1
    var coin: String?

    var validator: ValidatorItem?
    if let firstValue = publicKey, let firstItem = self.validatorsPickerSource[firstValue] {
      validator = firstItem
    } else if let publicKey = publicKey, publicKey.isValidPublicKey() {
      validator = ValidatorItem(publicKey: publicKey)
    }
    if let coinKey = val.0 {
      coin = self.coinsPickerSource[coinKey]?.coin
    }
    var amount = Decimal(string: val.2 ?? "")
    return (coin, validator, amount)
  }

  private var isButtonEnabled: Observable<Bool> {
    return isValidForm
  }

  private var isValidForm: Observable<Bool> {
    return form.map { (val) -> Bool in
      let (coin, _, amount) = val
      return coin != nil && (self.validator?.publicKey.isValidPublicKey() ?? false) && (amount ?? 0.0) > 0.0
    }
  }

  private let didSelectCoin = PublishSubject<[Int: String]>()
  private let validatorName = ReplaySubject<String>.create(bufferSize: 1)
  private let validatorPublicKey = ReplaySubject<String>.create(bufferSize: 1)
  private let didTapSend = PublishSubject<Void>()
  private let didTapUseMax = PublishSubject<Void>()
  private let didEndEditingValidator = PublishSubject<Void>()
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.timer(0, period: 1, scheduler: MainScheduler.instance).map {_ in}).merge()

  // MARK: - ViewModel

  var input: DelegateUnbondViewModel.Input!
  var output: DelegateUnbondViewModel.Output!
  var dependency: DelegateUnbondViewModel.Dependency!

  struct Input {
    var coin: BehaviorRelay<String?>
    var amount: BehaviorRelay<String?>
    var didTapClear: AnyObserver<Void>
    var didTapCoin: AnyObserver<Void>
    var didSelectCoin: AnyObserver<[Int: String]>
    var didTapSend: AnyObserver<Void>
    var didTapUseMax: AnyObserver<Void>
    var didSelectAutocompleteItem: AnyObserver<SearchTextFieldItem>
    var didTapShowValidators: AnyObserver<Void>
    var validator: BehaviorRelay<String?>
    var didEndEditingValidator: AnyObserver<Void>
  }

  struct Output {
    var validatorName: Observable<String>
    var validatorPublicKey: Observable<String>
    var showInput: Observable<Void>
    var showCoins: Observable<[[String]]>
    var isButtonEnabled: Observable<Bool>
    var title: Observable<String?>
    var description: Observable<String?>
    var errorMessage: Observable<String>
    var fee: Observable<String>
    var hasMultipleCoins: Observable<Bool>
    var autocompleteValidatorsItems: Observable<[SearchTextFieldItem]>
    var didTapShowValidators: Observable<Void>
    var disableValidatorChange: Observable<Bool>
    var showConfirmation: Observable<(String?, String?)>
    var coinTitle: Observable<String?>
    var lastBlock: Observable<NSAttributedString?>
  }

  struct Dependency {
    var validatorService: ValidatorService
    var balanceService: BalanceService
    var gateService: GateService
    var accountService: AccountService
    var coinService: CoinService
  }

  init(validator: ValidatorItem? = nil,
       coinName: String? = nil,
       isUnbond: Bool = false,
       maxUnbondAmounts: [String: Decimal]? = nil,
       dependency: Dependency) {

    super.init()

    self.isUnbond = isUnbond
    self.validator = validator

    if let validator = validator {
      self.validatorPublicKey.onNext(TransactionTitleHelper.title(from: validator.publicKey))
      self.validatorName.onNext(validator.name ?? TransactionTitleHelper.title(from: validator.publicKey))
      self.validatorSubject.accept(validator.publicKey)
    }

    if let coinName = coinName, let balance = maxUnbondAmounts?[coinName] {
      let item = SpendCoinPickerItem(coin: coinName, balance: balance)
      self.coin.accept(item.title ?? "")
    }

    maxUnbondAmounts?.forEach({ (val) in
      let item = SpendCoinPickerItem(coin: val.key, balance: val.value)
      guard let title = item.title else {
        return
      }
      self.coinsPickerSource[title] = item
    })

    self.maxUnbondAmounts = maxUnbondAmounts

    self.dependency = dependency

    self.input = Input(coin: coin,
                       amount: amount.value,
                       didTapClear: shouldClear.asObserver(),
                       didTapCoin: didTapCoin.asObserver(),
                       didSelectCoin: didSelectCoin.asObserver(),
                       didTapSend: didTapSend.asObserver(),
                       didTapUseMax: didTapUseMax.asObserver(),
                       didSelectAutocompleteItem: didSelectAutocompleteItem.asObserver(),
                       didTapShowValidators: didTapShowValidators.asObserver(),
                       validator: validatorSubject,
                       didEndEditingValidator: didEndEditingValidator.asObserver()
    )

    self.output = Output(validatorName: validatorName.asObservable(),
                         validatorPublicKey: validatorPublicKey.asObservable(),
                         showInput: shouldClear.asObservable(),
                         showCoins: showCoinsObservable(),
                         isButtonEnabled: isButtonEnabled,
                         title: Observable.just((isUnbond ? "Unbond".localized() : "Delegate".localized())),
                         description: {
                          if isUnbond {
                            return Observable.just("The process will be finalized within ~30 days after the request has been sent")
                          }
                          return Observable.just("Delegate your coins to validators and receive related regular payments")
                         }(),
                         errorMessage: errorMessage.asObservable(),
                         fee: Observable.combineLatest(self.dependency.gateService.currentGas(),
                                                       self.dependency.gateService.commission()).map({ (gas, commissions) -> String in
                          let comType = self.isUnbond ? (commissions.transactionCommissions[.unbond] ?? RawTransactionType.unbond.commission())
                            : (commissions.transactionCommissions[.delegate] ?? RawTransactionType.delegate.commission())
                          let com = (Decimal(gas) * comType).PIPToDecimal()
                          let commissionCoin = self.dependency.gateService.lastComission?.coin?.symbol ?? ""
                          let fee = CurrencyNumberFormatter.decimalFormatter.formattedDecimal(with: com) + " " + commissionCoin
                          return fee
                         }),
                         hasMultipleCoins: {
                          return self.dependency.balanceService.balances().map { (value) -> Bool in
                           value.balances.keys.count > 1
                          }
                         }(),
                         autocompleteValidatorsItems: autocomplete.autocompleteValidatorsItems.asObservable(),
                         didTapShowValidators: didTapShowValidators.asObservable(),
                         disableValidatorChange: Observable.just(isUnbond),
                         showConfirmation: didTapSend.withLatestFrom(form).map {
                          let amount = CurrencyNumberFormatter.coinFormatter.formattedDecimal(with: $0.2 ?? 0.0) + " " + ($0.0 ?? "")
                          let validatorName = self.validator?.name ?? TransactionTitleHelper.title(from: self.validator?.publicKey ?? "")
                          return (amount, validatorName)
                         }.asObservable(),
                         coinTitle: Observable.just(isUnbond ? "Coin you want to unbond".localized() : "Coin".localized()),
                         lastBlock: balanceTitleObservable.withLatestFrom(self.dependency.balanceService.lastBlockAgo()).map {
                          let ago = Date().timeIntervalSince1970 - ($0 ?? 0)
                          return self.headerViewLastUpdatedTitleText(seconds: ago)
                         }
    )

    bind()
  }

  // MARK: -

  func showCoinsObservable() -> Observable<[[String]]> {
    return didTapCoin.map { (_) -> [[String]] in
      return [self.coinsPickerSource.values.sorted(by: { (item1, item2) -> Bool in
        let key1 = item1.coin ?? ""
        let key2 = item2.coin ?? ""
        return (key1 == Coin.baseCoin().symbol!) ? true
          : (key2 == Coin.baseCoin().symbol!) ? false
          : (key1 < key2)
        }).map { (item) -> String in
          return item.title ?? ""
        }]
    }
  }

  func currentCommission() -> Decimal {
    return RawTransactionType.delegate.commission().PIPToDecimal()
  }

  func bind() {

    shouldClear.subscribe(onNext: { (_) in
      self.validator = nil
    }).disposed(by: disposeBag)

    didSelectAutocompleteItem.subscribe(onNext: { [weak self] (item) in
      if let validatorItem = self?.autocomplete.itemsSource[item.id] {
        self?.validator = validatorItem
      }
    }).disposed(by: disposeBag)

    amount.value.distinctUntilChanged().debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
      .map { (val) -> String? in
        return AmountHelper.transformValue(value: val)
      }.subscribe(onNext: { [weak self] val in
        self?.amount.value.accept(val)
      }).disposed(by: disposeBag)

    didTapUseMax.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).withLatestFrom(coin).subscribe(onNext: { [weak self] (coin) in
      guard let `self` = self else { return }

      var amount: String?
      guard let coin = coin, let balance = self.coinsPickerSource[coin]?.balance else { return }
      amount = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: CurrencyNumberFormatter.decimalFormatter, maxPlaces: 18)
      self.amount.value.accept(amount)
      self.amount.isMax.accept(true)
    }).disposed(by: disposeBag)

    self.dependency.validatorService.validators().subscribe(onNext: { [weak self] (items) in
      guard let `self` = self else { return }

      var autocompleteItems = [SearchTextFieldItem]()
      items.forEach({ (item) in
        guard item.isOnline else { return }
        self.validatorsPickerSource[self.pickerTitle(from: item)] = item
        let autocompleteItem = SearchTextFieldItem(id: String.random(),
                                                   title: item.name ?? TransactionTitleHelper.title(from: item.publicKey), subtitle: item.publicKey,
                                                   image: UIImage(named: "DelegateIcon"),
                                                   imageURL: URL.validatorURL(with: item.publicKey))
        autocompleteItems.append(autocompleteItem)
        self.autocomplete.itemsSource[autocompleteItem.id] = item
      })
      self.autocomplete.autocompleteValidatorsItems.onNext(autocompleteItems)

      if let validator = self.validator {
        self.validator = validator
      } else {
        self.shouldClear.onNext(())
      }
    }).disposed(by: disposeBag)

    self.dependency.balanceService.balances().filter { _ in !self.isUnbond }.subscribe(onNext: { [weak self] (val) in
      guard let `self` = self else { return }

      self.balances = val.balances.mapValues({ (balance) -> Decimal in
        return balance.0
      })

      self.coinsPickerSource = [:]
      val.balances.keys.forEach { (coin) -> Void in
        let item = SpendCoinPickerItem(coin: coin, balance: val.balances[coin]?.0 ?? 0.0, formatter: self.coinFormatter)
        guard let title = item.title else { return }

        self.coinsPickerSource[title] = item

        //If unbond - don't change coin name on default
        if !self.isUnbond && coin == Coin.baseCoin().symbol {
          self.coin.accept(title)
        }
      }
    }).disposed(by: disposeBag)

    didEndEditingValidator.withLatestFrom(form).subscribe(onNext: { [weak self] (val) in
      if let validator = val.1 {
        self?.validator = validator
      }
    }).disposed(by: disposeBag)

    didSelectCoin.subscribe(onNext: { [weak self] (val) in
      guard let selectedCoin = val.values.first,
        let selectedItem = self?.coinsPickerSource[selectedCoin] else {
          return
      }
      self?.coin.accept(selectedItem.title)
    }).disposed(by: disposeBag)

  }

  lazy var sendObservable = Observable.combineLatest(self.form, self.dependency.balanceService.account).share()

  func performSend() -> Observable<Event<(String?, Decimal?)>> {
    return Observable.just(())
      .withLatestFrom(self.isValidForm).filter { $0 == true }
      .do(onNext: { [unowned self] (_) in
        self.impact.onNext(.hard)
        self.sound.onNext(.bip)
      })
      .flatMap { _ in self.dependency.coinService.updateCoinsWithResponse() }
      .withLatestFrom(Observable.combineLatest(form, dependency.balanceService.account))
      .flatMap { [weak self] (val) -> Observable<Event<RawTransaction>> in
        guard let `self` = self,
          let coin = val.0.0,
          let coinId = self.dependency.coinService.coinId(symbol: coin),
          let validator = self.validator,
          let amount = val.0.2,
          let aPublicKey = PublicKey(validator.publicKey),
          let account = val.1 else { return Observable.empty() }

        let baseCoinBalance = (self.balances[Coin.baseCoin().symbol!] ?? 0.0)
        //Update amount if needed
        var newAmount = amount
        var gasCoinId = coinId

        //In unbond - send tx as is
        if self.isUnbond {
          //Gas coin here - MNT
          gasCoinId = Coin.baseCoin().id!
          return self.makeTransaction(account: account,
                                      gasCoinId: gasCoinId,
                                      publicKey: aPublicKey,
                                      coinId: coinId,
                                      amount: newAmount).materialize()
        }

        if coinId == Coin.baseCoin().id! {
          //check if can pay comission
          let amountWithCommission = amount + self.currentCommission()
          if baseCoinBalance >= amountWithCommission {
            //all good - send tx
          } else {
            //check if USE MAX
            //IF yes - subtract commission
            //else  - error
            if self.amount.isMax.value {
              newAmount = amount - self.currentCommission()
            }
          }
        } else {
          //check if can pay with baseCoin
          if baseCoinBalance >= self.currentCommission() {
            //all good - send tx
            gasCoinId = Coin.baseCoin().id!
          } else {
            //else - is isMax send estimate request and subtract commission from amount
            if self.amount.isMax.value {
              return self.makeTransactionWithCommission(account: account,
                                                        gasCoinId: gasCoinId,
                                                        publicKey: aPublicKey,
                                                        coinId: coinId,
                                                        amount: amount).materialize()
            }
          }
        }

        return self.makeTransaction(account: account,
                                    gasCoinId: gasCoinId,
                                    publicKey: aPublicKey,
                                    coinId: coinId,
                                    amount: newAmount).materialize()

      }.flatMap { [unowned self] (event) -> Observable<Event<String>> in
        switch event {
        case .completed:
          return Observable.empty().materialize()
        case .next(let transaction):
          return self.signTransaction(rawTransaction: transaction).materialize()
        case .error(let error):
          return Observable.error(error).materialize()
        }
      }.flatMap({ [unowned self] (transaction) -> Observable<Event<(String?, Decimal?)>> in
        switch transaction {
        case .error(let error):
          return Observable.error(error).materialize()

        case .completed:
          return Observable.never().materialize()

        case .next(let signedTx):
          return self.dependency.gateService.send(rawTx: signedTx).materialize()
        }
      }).do(onNext: { [unowned self] (val) in
        switch val {
        case .next(_):
          self.dependency.validatorService.lastUsedPublicKey = self.validator?.publicKey
          self.clearForm()

        case .error(let error):
          self.handleError(error)

        case .completed:
          return
        }
      })
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
    self.amount.value.accept(nil)
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

  func makeTransactionWithCommission(account: AccountItem,
                                     gasCoinId: Int,
                                     publicKey: PublicKey,
                                     coinId: Int,
                                     amount: Decimal) -> Observable<RawTransaction> {

    return makeTransaction(account: account,
                           gasCoinId: gasCoinId,
                           publicKey: publicKey,
                           coinId: coinId,
                           amount: amount)
      .flatMap { transaction -> Observable<Event<Decimal>> in
        let rawTx = transaction.encode()?.toHexString() ?? ""
        return self.dependency.gateService.estimateComission(rawTx: rawTx).materialize()
      }.flatMap { [unowned self] (event) -> Observable<RawTransaction> in
        switch event {
        case .next(let commission):
          //TODO: remove PIPToDecimal and migrate to a newer gateService
          let newAmount = amount - commission.PIPToDecimal()
          if newAmount > 0 {
            return self.makeTransaction(account: account,
                                        gasCoinId: coinId,
                                        publicKey: publicKey,
                                        coinId: coinId,
                                        amount: newAmount)
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

  func makeTransaction(account: AccountItem, gasCoinId: Int, publicKey: PublicKey, coinId: Int, amount: Decimal) -> Observable<RawTransaction> {
    return Observable.combineLatest(
      self.dependency.gateService.nonce(address: account.address),
      self.dependency.gateService.currentGas()
    ).take(1).flatMap { [unowned self] val -> Observable<RawTransaction> in
      let nonce = val.0
      let gas = val.1
      return Observable.create { (observer) -> Disposable in
        if self.isUnbond {
          let transaction = UnbondRawTransaction(nonce: BigUInt(nonce+1),
                                                 gasPrice: gas,
                                                 gasCoinId: gasCoinId,
                                                 publicKey: publicKey.stringValue,
                                                 coinId: coinId,
                                                 value: BigUInt(decimal: amount, fromPIP: true) ?? BigUInt(0))
          observer.onNext(transaction)
        } else {
          let transaction = DelegateRawTransaction(nonce: BigUInt(nonce+1),
                                                   gasPrice: gas,
                                                   gasCoinId: gasCoinId,
                                                   publicKey: publicKey.stringValue,
                                                   coinId: coinId,
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
