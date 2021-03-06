//
//  SendViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterExplorer
import MinterMy
import BigInt
import SwiftValidator
import RxAppState
import RxBiBinding
import RxRelay
import AVFoundation
import GoldenKeystore

struct AccountPickerItem {
  var title: String?
  var address: String?
  var balance: Decimal?
  var coin: String?
}

class SendViewModel: BaseViewModel, ViewModel, WalletSelectableViewModel {// swiftlint:disable:this type_body_length

  enum SendViewModelError: Error {
    case noPrivateKey
    case insufficientFunds
    case invalidTransactionData
  }

  // MARK: - ViewModelProtocol

  var input: SendViewModel.Input!
  var output: SendViewModel.Output!
  var dependency: SendViewModel.Dependency!

  struct Input {
    var payload: AnyObserver<String?>
    var txScanButtonDidTap: AnyObserver<Void>
    var didScanQR: AnyObserver<String?>
    var contact: AnyObserver<ContactItem>
    var didTapSelectWallet: AnyObserver<Void>
    var viewDidAppear: AnyObserver<Void>
  }

  struct Output {
    var errorNotification: Observable<NotifiableError?>
    var txErrorNotification: Observable<NotifiableError?>
    var popup: Observable<PopupViewController?>
    var showViewController: Observable<UIViewController?>
    var openAppSettings: Observable<Void>
    var updateTableHeight: Observable<Void>
    var shouldShowAlert: Observable<String>
    var showContactsPicker: Observable<Void>
    var recipient: Observable<String?>
    var didProvideAutocomplete: Observable<Void>
    var wallet: Observable<String?>
    var timerText: Observable<NSAttributedString?>
    var usernameDidEndEditing: Observable<Void>
    var showSendSucceed: Observable<(String?, String?)>
    var didScanQR: Observable<String?>
  }

  struct Dependency {
    var balanceService: BalanceService
    var contactsService: ContactsService
    var recipientInfoService: RecipientInfoService
    var coinService: CoinService
  }

  var balanceService: BalanceService! {
    return self.dependency.balanceService
  }

  func showWalletObservable() -> Observable<Void> {
    return didTapSelectWallet.map {_ in}.asObservable()
  }

  // MARK: -

  private let didTapSelectWallet = PublishSubject<Void>()

  typealias FormChangedObservable = (String?, String?, String?, String?, String)

  private var didProvideAutocomplete = PublishSubject<Void>()
  private let showContactsPicker = PublishSubject<Void>()
  private let contact = PublishSubject<ContactItem>()
  private let updateTableHeight = PublishSubject<Void>()
  private let coinSubject = BehaviorRelay<String?>(value: "")
  private let recipientSubject = BehaviorRelay<String?>(value: "")
  private let forceUpdateRecipientHeight = PublishSubject<Void>()
  private let addressSubject = BehaviorRelay<String?>(value: "")
  private let amountSubject = BehaviorRelay<String?>(value: "")
  private let shouldShowAlertSubject = PublishSubject<String>()
  //used to update input amount value
  private let clearAmountBehavior = BehaviorRelay<String?>(value: "")
  private var formChangedObservable: Observable<FormChangedObservable> {
    return Observable.combineLatest(coinSubject.asObservable(),
                                    addressSubject.asObservable(),
                                    amountSubject.map({ (str) -> String? in
                                      return str?.replacingOccurrences(of: ",", with: ".")
                                    }).distinctUntilChanged(),
                                    payloadSubject.asObservable(),
                                    dependency.balanceService.account.filter({ (item) -> Bool in
                                      return (item?.address ?? "").isValidAddress()
                                    }).map({ (item) -> String in
                                      return item?.address ?? ""
                                    }))
  }
  private let openAppSettingsSubject = PublishSubject<Void>()
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.timer(0, period: 1, scheduler: MainScheduler.instance).map {_ in}).merge()
  private let usernameDidEndEditing = PublishSubject<Void>()
  private let showSendSucceed = PublishSubject<(String?, String?)>()

  let fakePK = Data(hex: "678b3252ce9b013cef922687152fb71d45361b32f8f9a57b0d11cc340881c999").toHexString()

  // MARK: -

  private var showViewControllerSubject = PublishSubject<UIViewController?>()

  var sections = Variable([BaseTableSectionItem]())
  private var _sections = Variable([BaseTableSectionItem]())

  //Formatters
  private let formatter = CurrencyNumberFormatter.decimalFormatter
  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  //Loading observables
  private var isLoadingAddressSubject = PublishSubject<Bool>()
  private var isLoadingNonceSubject = PublishSubject<Bool>()

  //State obervables
  private var didScanQRSubject = PublishSubject<String?>()
  private var addressStateSubject = PublishSubject<TextViewTableViewCell.State>()
  private var amountStateSubject = PublishSubject<TextFieldTableViewCell.State>()
  private var payloadStateObservable = PublishSubject<TextViewTableViewCell.State>()

  private var isMaxAmount = BehaviorRelay<Bool>(value: false)

  var isBaseCoin: Bool? {
    guard selectedCoin.value != nil else {
      return nil
    }
    return selectedCoin.value == Coin.baseCoin().symbol!
  }

  private func canPayCommissionWithBaseCoin(baseCoinBalance: Decimal) -> Bool {
    if baseCoinBalance >= commission() {
      return true
    }
    return false
  }

  private func commission() -> Decimal {
    let payloadCom = payloadComission().decimalFromPIP()
    let val = (payloadCom + RawTransactionType.sendCoin.commission()).PIPToDecimal()
    return Decimal(GateManager.shared.lastGas) * val
  }

  private func payloadComission() -> Decimal {
    return Decimal((try? clearPayloadSubject.value() ?? "")?.count ?? 0) * RawTransaction.payloadByteComissionPrice
  }

  private var lastBalances = [String: Decimal]()
  private var lastSentTransactionHash: String?
  private var selectedCoin = Variable<String?>(nil)
  private let accountManager = AccountManager()
  private let infoManager = InfoManager(httpClient: APIClient(headers: ["X-Minter-Chain-Id": "chilinet"]))
  private let payloadSubject = BehaviorSubject<String?>(value: "")
  private let clearPayloadSubject = BehaviorSubject<String?>(value: "")
  private let errorNotificationSubject = PublishSubject<NotifiableError?>()
  private let txErrorNotificationSubject = PublishSubject<NotifiableError?>()
  private let txScanButtonDidTap = PublishSubject<Void>()
  private let popupSubject = PublishSubject<PopupViewController?>()
  private let viewDidAppear = PublishSubject<Void>()
  private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
  var gasObservable: Observable<String> {
    return Observable.combineLatest(currentGas.asObservable(),
                                    clearPayloadSubject.asObservable(),
                                    formChangedObservable)
      .map({ [weak self] (obj) -> String in
        let payloadData = obj.2.3?.data(using: .utf8)
        let recipient = obj.2.1
        return self?.comissionText(recipient: recipient ?? "",
                                   for: obj.0,
                                   payloadData: payloadData) ?? ""
    })
  }

  // MARK: -

  init(dependency: Dependency) { // swiftlint:disable:this function_body_length cyclomatic_complexity
    super.init()

    self.dependency = dependency

    self.input = Input(payload: payloadSubject.asObserver(),
                       txScanButtonDidTap: txScanButtonDidTap.asObserver(),
                       didScanQR: didScanQRSubject.asObserver(),
                       contact: contact.asObserver(),
                       didTapSelectWallet: didTapSelectWallet.asObserver(),
                       viewDidAppear: viewDidAppear.asObserver()
    )

    self.output = Output(errorNotification: errorNotificationSubject.asObservable(),
                         txErrorNotification: txErrorNotificationSubject.asObservable(),
                         popup: popupSubject.asObservable(),
                         showViewController: showViewControllerSubject.asObservable(),
                         openAppSettings: openAppSettingsSubject.asObservable(),
                         updateTableHeight: updateTableHeight.asObservable(),
                         shouldShowAlert: shouldShowAlertSubject.asObservable(),
                         showContactsPicker: showContactsPicker.asObservable(),
                         recipient: recipientSubject.asObservable(),
                         didProvideAutocomplete: didProvideAutocomplete.asObservable(),
                         wallet: walletTitleObservable(),
                         timerText: balanceTitleObservable.withLatestFrom(balanceService.lastBlockAgo()).map {
                          let ago = Date().timeIntervalSince1970 - ($0 ?? 0)
                          return self.headerViewLastUpdatedTitleText(seconds: ago) },
                         usernameDidEndEditing: usernameDidEndEditing.asObservable(),
                         showSendSucceed: showSendSucceed.asObservable(),
                         didScanQR: didScanQRSubject.asObservable()
    )

    amountSubject.distinctUntilChanged()//.observeOn(MainScheduler.asyncInstance)
      .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
      .map { (val) -> String? in
        return AmountHelper.transformValue(value: val)
      }.subscribe(onNext: { val in
        self.amountSubject.accept(val)
      }).disposed(by: disposeBag)

    payloadSubject.asObservable().subscribe(onNext: { (payld) in
      if GoldenKeystore.mnemonicIsValid(payld ?? "") {
        self.shouldShowAlertSubject.onNext("""
YOU ARE ABOUT TO SEND SEED PHRASE IN THE MESSAGE ATTACHED TO THIS TRANSACTION.\nIF YOU DO THIS, ANYONE WILL BE ABLE TO SEE IT AND ACCESS FUNDS!
""")
      }

      let data = (payld ?? "").data(using: .utf8) ?? Data()
      if data.count > RawTransaction.maxPayloadSize {
        self.payloadStateObservable.onNext(.invalid(error: "TOO MANY SYMBOLS".localized()))
      } else {
        self.payloadStateObservable.onNext(.default)
      }
    }).disposed(by: disposeBag)

    payloadSubject.asObservable().map({ (val) -> String? in
      var newVal = val
      while newVal?.data(using: .utf8)?.count ?? 0 > RawTransaction.maxPayloadSize {
        newVal?.removeLast()
      }
      return newVal
    }).subscribe(onNext: { [weak self] (val) in
      self?.clearPayloadSubject.onNext(val)
    }).disposed(by: disposeBag)

    dependency.balanceService.balances()
      .subscribe(onNext: { [weak self] (val) in
        self?.lastBalances = val.balances.mapValues({ (val) -> Decimal in
          return val.0
        })

        if let selCoin = self?.selectedCoin.value, nil == val.balances[selCoin] {
          self?.selectedCoin.value = nil
          self?.coinSubject.accept(nil)
        }
        self?.sections.value = self?.createSections() ?? []
      }).disposed(by: disposeBag)

    sections.asObservable()
      .subscribe(onNext: { [weak self] (items) in
        self?._sections.value = items
      }).disposed(by: disposeBag)

    dependency.balanceService.account
      .subscribe(onNext: { [weak self] (_) in
        self?.amountSubject.accept(nil)
        self?.sections.value = self?.createSections() ?? []
      }).disposed(by: disposeBag)

    didScanQRSubject.asObservable()
      .subscribe(onNext: { [weak self] (val) in
        guard let `self` = self else { return }
        let url = URL(string: val ?? "")
        if true == val?.isValidAddress() {
          self.recipientSubject.accept(val)
          return
        } else if true == val?.isValidPublicKey() {
          return
        } else if let url = url,
          let rawViewController = RawTransactionRouter.rawTransactionViewController(with: url,
                                                                                    balanceService: self.dependency.balanceService,
                                                                                    coinService: self.dependency.coinService) {
            self.showViewControllerSubject.onNext(rawViewController)
            return
        }
        self.errorNotificationSubject.onNext(NotifiableError(title: "Invalid transaction data".localized(), text: nil))
      }).disposed(by: disposeBag)

    formChangedObservable.subscribe(onNext: { [weak self] (val) in
      let amount = val.2
      let lastIsMaxAmountValue = self?.isMaxAmount.value ?? false
      self?.isMaxAmount.accept(false)

      if self?.recipientSubject.value == nil || self?.recipientSubject.value == "" {
        self?.addressStateSubject.onNext(.default)
      }

      if amount == nil || amount == "" {
        self?.amountStateSubject.onNext(.default)
      } else {
        let amnt = amount ?? ""
        if let dec = Decimal(string: amnt), dec >= 0 {
          if let selectedCoin = self?.selectedCoin.value, let selectedCoinBalance = self?.lastBalances[selectedCoin], lastIsMaxAmountValue {
            let isMax = (Decimal.PIPComparableBalance(from: dec) == Decimal.PIPComparableBalance(from: selectedCoinBalance))
            if isMax {
              self?.isMaxAmount.accept(true)
            }
          }
          self?.amountStateSubject.onNext(.default)
        } else {
          self?.amountStateSubject.onNext(.invalid(error: "AMOUNT IS INCORRECT".localized()))
        }
      }
    }).disposed(by: disposeBag)

    recipientSubject.distinctUntilChanged()
      .do(onNext: { [weak self] (rec) in
        if self?.isValidMinterRecipient(recipient: rec ?? "") ?? false {
          self?.addressSubject.accept(rec)
          self?.addressStateSubject.onNext(.default)
        } else {
          self?.addressSubject.accept(nil)
        }
      }).filter { [weak self] in
        return !(self?.isValidMinterRecipient(recipient: $0 ?? "") ?? false)
      }.throttle(.seconds(2), scheduler: MainScheduler.instance)
      .do(onNext: { [weak self] (rec) in
        if !(self?.isToValid(to: rec ?? "") ?? false) && (rec ?? "").count >= 5 {
          self?.addressStateSubject.onNext(.invalid(error: "INVALID VALUE".localized()))
        } else {
          if rec?.isValidPublicKey() == true {
            self?.addressStateSubject.onNext(.invalid(error: "For delegations please go to Delegations section".uppercased().localized()))
          } else {
            self?.addressStateSubject.onNext(.default)
          }
        }
        if self?.isValidMinterRecipient(recipient: rec ?? "") ?? false {
          self?.addressSubject.accept(rec)
        }
      }).filter({ [weak self] (rec) -> Bool in
        return self?.isToValid(to: rec ?? "") ?? false
      }).flatMap { [unowned self] (rec) -> Observable<Event<ContactItem?>> in
        let term = (rec ?? "").lowercased()
        return self.dependency.contactsService.contactBy(name: term).materialize()
      }.do(onNext: { [weak self] (_) in
        self?.isLoadingAddressSubject.onNext(false)
      }, onError: { [weak self] (_) in
        self?.isLoadingAddressSubject.onNext(false)
      }, onCompleted: { [weak self] in
        self?.isLoadingAddressSubject.onNext(false)
      }, onSubscribe: { [weak self] in
        self?.isLoadingAddressSubject.onNext(true)
      }).subscribe(onNext: { [weak self] (event) in
        switch event {
        case .completed:
          break
        case .next(let contact):
          guard let addr = contact?.address else { return }
          if self?.isValidMinterRecipient(recipient: addr) ?? false {
            self?.addressSubject.accept(addr)
            self?.addressStateSubject.onNext(.default)
          }
        case .error(_):
          self?.addressStateSubject.onNext(.invalid(error: "USERNAME CAN NOT BE FOUND".localized()))
        }
      }).disposed(by: disposeBag)

    txScanButtonDidTap.asObservable().subscribe(onNext: { [weak self] (_) in
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          if granted {} else {
            self?.openAppSettingsSubject.onNext(())
          }
        }
      case .denied:
        self?.openAppSettingsSubject.onNext(())
        return

      case .restricted:
        self?.openAppSettingsSubject.onNext(())
        return

      default:
        return
      }
    }).disposed(by: disposeBag)

    contact.subscribe(onNext: { [weak self] (item) in
      self?.recipientSubject.accept(item.name ?? item.address)
      self?.forceUpdateRecipientHeight.onNext(())
    }).disposed(by: disposeBag)

    viewDidAppear.withLatestFrom(GateManager.shared.minGas())
      .subscribe(onNext: { [weak self] (gas) in
        self?.currentGas.onNext(gas)
      }).disposed(by: disposeBag)

    self.dependency.contactsService.contactsChanged().filter({ (_) -> Bool in
      return self.addressSubject.value != nil
    }).withLatestFrom(self.recipientSubject).flatMap {
      return self.dependency.contactsService.contactBy(name: $0 ?? "")
    }.subscribe(onNext: { [weak self] (val) in
      if let address = self?.addressSubject.value {
        self?.recipientSubject.accept(address)
      }
    }).disposed(by: disposeBag)
  }

  // MARK: - Sections

  func createSections() -> [BaseTableSectionItem] {
    let username = UsernameTableViewCellItem(reuseIdentifier: "UsernameTableViewCell",
                                             identifier: CellIdentifierPrefix.address.rawValue)
    username.title = "To (Mx Address or Name)".localized()
    username.isLoadingObservable = isLoadingAddressSubject.asObservable()
    username.stateObservable = addressStateSubject.asObservable()
    username.keybordType = .emailAddress
    (username.text <-> recipientSubject).disposed(by: disposeBag)
    forceUpdateRecipientHeight.subscribe(username.forceUpdateHeight).disposed(by: disposeBag)
    username.didTapContacts.subscribe(onNext: { [weak self] _ in
      self?.showContactsPicker.onNext(())
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).disposed(by: disposeBag)
    username.didEndEditing.subscribe(usernameDidEndEditing).disposed(by: disposeBag)

    let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell",
                                       identifier: CellIdentifierPrefix.coin.rawValue)
    coin.title = "Coin".localized()
    if nil != self.selectedCoin.value {
      let item = accountPickerItems().filter { (item) -> Bool in
        if let object = item.object as? AccountPickerItem {
          return selectedCoin.value == object.coin
        }
        return false
      }
      if let first = item.first {
        coin.selected = first
      }
    } else if let item = accountPickerItems().first {
      coin.selected = item
      if let object = item.object as? AccountPickerItem {
        selectedCoin.value = object.coin
        coinSubject.accept(object.coin)
      }
    }

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell1")
    blank1.height = 5.0

    let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell2")
    blank2.height = 5.0

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell3")
    blank3.height = 5.0

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell4")
    blank4.height = 22.0

    let blank5 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell5")
    blank5.height = 19.0

    let amount = AmountTextFieldTableViewCellItem(reuseIdentifier: "AmountTextFieldTableViewCell",
                                                  identifier: CellIdentifierPrefix.amount.rawValue)
    amount.title = "Amount".localized()
    amount.stateObservable = amountStateSubject.asObservable()
    amount.keyboardType = .decimalPad
    (amount.text <-> amountSubject).disposed(by: disposeBag)
    amount.output?.didTapUseMax.withLatestFrom(
      Observable.combineLatest(formChangedObservable, dependency.balanceService.balances())
      ).map({ [weak self] (val) -> String? in
        guard let _self = self else { return nil } //swiftlint:disable:this identifier_name
        let form = val.0
        let balances = val.1

        guard let coin = form.0 else { return nil }

        let balance = balances.balances[coin]?.0 ?? 0.0
        return _self.formatter.formattedDecimal(with: balance, maxPlaces: 18)
      }).subscribe(onNext: { [weak self] (val) in
        self?.impact.onNext(.light)
        self?.sound.onNext(.click)
        self?.amountSubject.accept(val)
        self?.isMaxAmount.accept(true)
      }).disposed(by: disposeBag)

    let payload = SendPayloadTableViewCellItem(reuseIdentifier: "SendPayloadTableViewCell",
                                               identifier: "SendPayloadTableViewCell_Payload")
    payload.title = "You can add a message to your transaction".localized()
    payload.keybordType = .default
    payload.stateObservable = payloadStateObservable.asObservable()
    payload.titleObservable = clearPayloadSubject.asObservable()
    payload.didTapAddMessage.subscribe(onNext: { [weak self] _ in
      self?.updateTableHeight.onNext(())
    }).disposed(by: disposeBag)

    let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
                                        identifier: CellIdentifierPrefix.fee.rawValue)
    fee.title = "Transaction Fee".localized()
    let payloadData = (try? clearPayloadSubject.value() ?? "")?.data(using: .utf8)
    fee.subtitle = self.comissionText(recipient: recipientSubject.value ?? "", for: 1, payloadData: payloadData)
    fee.subtitleObservable = self.gasObservable

    let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                       identifier: CellIdentifierPrefix.blank.rawValue)
    blank.height = 6

    let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                         identifier: CellIdentifierPrefix.button.rawValue)
    button.title = "Continue".localized()
    button.buttonPattern = "purple"
    button.isButtonEnabledObservable = formChangedObservable.map({ (val) -> Bool in
      let coin = val.0
      let recipient = val.1
      let amount = val.2
      return !(recipient ?? "").isEmpty && !(amount ?? "").isEmpty && !(coin ?? "").isEmpty
    })

    button.output?.didTapButton
      .subscribe(onNext: { [weak self] () in
        let defaultTitle = self?.recipientSubject.value ?? ""
        let recipient = self?.dependency.recipientInfoService.title(for: defaultTitle) ?? defaultTitle
        let amount = Decimal(string: self?.amountSubject.value ?? "") ?? 0
        let address = self?.addressSubject.value ?? ""
        let sendVM = self?.sendPopupViewModel(to: recipient,
                                             address: address,
                                             amount: amount)
        let sendPopup = SendPopupViewController.initFromStoryboard(name: "Popup")
        sendPopup.viewModel = sendVM
        self?.popupSubject.onNext(sendPopup)
        self?.impact.onNext(.hard)
        self?.sound.onNext(.bip)
      }).disposed(by: self.disposeBag)

    let section = BaseTableSectionItem(identifier: "SendSection",
                                       header: "SEND COINS",
                                       items: [blank, coin, blank1, amount, blank2, username, blank3, payload, blank4, fee, blank5, button])

    return [section]
  }

  func headerViewLastUpdatedTitleText(seconds: TimeInterval) -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(string: "Last updated ".localized(),
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.defaultFont(of: 12.0)]))
    var dateText = "\(Int(seconds)) seconds"
    if seconds < 5 {
      dateText = "just now".localized()
    } else if seconds > 60 * 60 {
      dateText = "more than an hour".localized()
    } else if seconds > 60 {
      dateText = "more than a minute".localized()
    }
    string.append(NSAttributedString(string: dateText,
                                     attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                  .font: UIFont.boldFont(of: 12.0)]))
    if seconds >= 5 {
      string.append(NSAttributedString(string: " ago".localized(),
                                       attributes: [.foregroundColor: UIColor.mainBlackColor(),
                                                    .font: UIFont.defaultFont(of: 12.0)]))
    }
    return string
  }

  // MARK: - Validation

  func submitField(item: BaseCellItem, value: String) {
    self._sections.value = self.createSections()
  }

  func isToValid(to: String) -> Bool {
    return to.isValidContactName() || self.isValidMinterRecipient(recipient: to)
  }

  func shouldShowRecipientError(for recipient: String) -> Bool {
    return recipient.isEmpty || recipient.count < 6
  }

  func isValidMinterRecipient(recipient: String) -> Bool {
    return recipient.isValidAddress()
  }

  func isAmountValid(amount: Decimal) -> Bool {
    return AmountValidator.isValid(amount: amount)
  }

  // MARK: - Rows

  func rowsCount(for section: Int) -> Int {
    return _sections.value[safe: section]?.items.count ?? 0
  }

  func cellItem(section: Int, row: Int) -> BaseCellItem? {
    return _sections.value[safe: section]?.items[safe: row]
  }

  // MARK: -

  func accountPickerItems() -> [PickerTableViewCellPickerItem] {
    var ret = [AccountPickerItem]()
    let balances = self.lastBalances
    var blns = balances.keys.filter({ (coin) -> Bool in
      return coin != (Coin.baseCoin().symbol ?? "")
    }).sorted(by: { (val1, val2) -> Bool in
      return val1 < val2
    })
    blns.insert((Coin.baseCoin().symbol ?? ""), at: 0)
    blns.forEach({ (coin) in
      let balance = (balances[coin] ?? 0.0)
      let balanceString = coinFormatter.formattedDecimal(with: balance)
      let title = coin + " (" + balanceString + ")"
      let item = AccountPickerItem(title: title,
                                   balance: balance,
                                   coin: coin)
      ret.append(item)
    })
    return ret.map({ (account) -> PickerTableViewCellPickerItem in
      return PickerTableViewCellPickerItem(title: account.title, object: account)
    })
  }

  func selectedPickerItem() -> PickerTableViewCellPickerItem? {
    guard let coin = selectedCoin.value else {
      return nil
    }
    let balances = lastBalances
    guard let balance = balances[coin] else {
      return nil
    }
    let balanceString = coinFormatter.formattedDecimal(with: balance)
    let title = coin + " (" + balanceString + ")"
    let item = AccountPickerItem(title: title,
                                 balance: balance,
                                 coin: coin)
    return PickerTableViewCellPickerItem(title: item.title, object: item)
  }

  // MARK: -

  func accountPickerSelect(item: AccountPickerItem) {
    selectedCoin.value = item.coin
    coinSubject.accept(item.coin)
  }

  // MARK: -

  func send() {
    Observable<Void>.just(())
      .withLatestFrom(dependency.balanceService.account)
      .filter({ (item) -> Bool in
        return (item?.address ?? "").isValidAddress()
      }).map({ (account) -> String in
        return account?.address ?? ""
      }).flatMap({ (address) -> Observable<(Int, Int)> in
        return Observable.combineLatest(
          GateManager.shared.nonce(address: address),
          GateManager.shared.minGas()).take(1)
      }).do(onError: { [weak self] (error) in
        self?.errorNotificationSubject.onNext(NotifiableError(title: "Can't get nonce"))
      }, onCompleted: { [weak self] in
        self?.isLoadingNonceSubject.onNext(false)
      }, onSubscribe: { [weak self] in
        self?.isLoadingNonceSubject.onNext(true)
      }).map({ (val) -> (Int, Int) in
        return (val.0+1, val.1)
      }).flatMapLatest({ (val) -> Observable<((Int, Int), FormChangedObservable, BalanceService.BalancesResponse)> in
        return Observable.zip(
          Observable.just(val),
          self.formChangedObservable.asObservable(),
          self.dependency.balanceService.balances()
        )
      }).flatMapLatest({ (val) -> Observable<String?> in
        let nonce = BigUInt(val.0.0)
        let amount = (Decimal(string: val.1.2 ?? "") ?? Decimal(0))
        let coinSymbol = val.1.0 ?? ""
        let coinId = self.dependency.coinService.coinId(symbol: coinSymbol) ?? Coin.baseCoin().id!
        let recipient = val.1.1 ?? ""
        let payload = val.1.3 ?? ""
        let selectedAddress = val.1.4
        let baseCoinBalance = val.2.baseCoinBalance
        let selectedAddressBalance = val.2.balances[coinSymbol]?.0 ?? 0.0

        guard selectedAddress.isValidAddress() else { return Observable.error(SendViewModelError.noPrivateKey) }

        return self.prepareTx(nonce: nonce,
                              amount: amount,
                              selectedCoinBalance: selectedAddressBalance,
                              recipient: recipient,
                              coinId: coinId,
                              payload: payload,
                              selectedAddress: selectedAddress,
                              canPayCommissionWithBaseCoin: self.canPayCommissionWithBaseCoin(baseCoinBalance: baseCoinBalance))
      }).flatMapLatest({ (signedTx) -> Observable<(String?, Decimal?)> in
        return GateManager.shared.send(rawTx: signedTx)
      }).subscribe(onNext: { [weak self] (val) in
        self?.dependency.balanceService.updateBalance()
        self?.dependency.balanceService.updateDelegated()

        self?.lastSentTransactionHash = val.0

        self?.sections.value = self?.createSections() ?? []
        let rec = self?.recipientSubject.value ?? ""
        let address = self?.addressSubject.value ?? ""

        self?.dependency.contactsService.lastUsedAddress = address

        let recipient = self?.dependency.recipientInfoService.title(for: rec) ?? rec

        self?.showSendSucceed.onNext((recipient, address))
        self?.clear()
      }, onError: { [weak self] (error) in
        self?.handle(error: error)
      }, onCompleted: { [weak self] in
        self?.isLoadingNonceSubject.onNext(false)
      }).disposed(by: disposeBag)
  }

  func clear() {
    self.clearPayloadSubject.onNext(nil)
    self.recipientSubject.accept(nil)
    self.amountSubject.accept(nil)
    self.payloadSubject.onNext(nil)
  }

  func submitSendButtonTaped() {
    send()
  }

  func sendCancelButtonTapped() {}

  // MARK: -

  func rawTransaction(nonce: BigUInt,
                      gasCoinId: Int,
                      recipient: String,
                      value: BigUInt,
                      coinId: Int,
                      payload: String) -> RawTransaction? {

    var rawTx: RawTransaction?
    let gasPrice = (try? currentGas.value()) ?? 1
    if recipient.isValidAddress() {
      rawTx = SendCoinRawTransaction(nonce: nonce,
                                     gasPrice: gasPrice,
                                     gasCoinId: gasCoinId,
                                     to: recipient,
                                     value: value,
                                     coinId: coinId)
    }
    rawTx?.payload = payload.data(using: .utf8) ?? Data()
    return rawTx
  }

  func prepareTx(
    nonce: BigUInt,
    amount: Decimal,
    selectedCoinBalance: Decimal,
    recipient: String,
    coinId: Int,
    payload: String,
    selectedAddress: String,
    canPayCommissionWithBaseCoin: Bool) -> Observable<String?> {

      return Observable.create { (observer) -> Disposable in

        let isMax = self.isMaxAmount.value

        let isBaseCoin = coinId == Coin.baseCoin().id!
        let preparedAmount = amount.decimalFromPIP()
        let commission = self.commission()
        if
          let mnemonic = self.accountManager.mnemonic(for: selectedAddress),
          let seed = self.accountManager.seed(mnemonic: mnemonic),
          let newPk = try? self.accountManager.privateKey(from: seed) {

          var gasCoinId: Int = Coin.baseCoin().id!
          var value: BigUInt = BigUInt(0)

          if isMax {
            if isBaseCoin {
              let amountWithCommission = max(0, amount - commission)
              if selectedCoinBalance < amountWithCommission {
                observer.onError(SendViewModelError.insufficientFunds)
              } else {
                value = BigUInt(decimal: amountWithCommission.decimalFromPIP()) ?? BigUInt(0)
              }
            } else if !canPayCommissionWithBaseCoin {
              let preparedAmountBigInt = BigUInt(decimal: preparedAmount)!
              let fakeTx = self.rawTransaction(nonce: nonce,
                                               gasCoinId: coinId,
                                               recipient: recipient,
                                               value: preparedAmountBigInt,
                                               coinId: coinId,
                                               payload: payload)

              guard let comissionTx = fakeTx else {
                observer.onError(SendViewModelError.invalidTransactionData)
                observer.onCompleted()
                return Disposables.create()
              }

              let fakeSignedTx = RawTransactionSigner.sign(rawTx: comissionTx, privateKey: self.fakePK)
              GateManager.shared.estimateTXCommission(for: fakeSignedTx!) { (commission, error) in
                guard error == nil else {
                  observer.onError(error!)
                  observer.onCompleted()
                  return
                }
                let normalizedCommission = commission!.PIPToDecimal()
                let normalizedAmount = BigUInt(decimal: (amount - normalizedCommission).decimalFromPIP()) ?? BigUInt(0)
                if let rawTx: RawTransaction = self.rawTransaction(nonce: nonce,
                                                                gasCoinId: coinId,
                                                                recipient: recipient,
                                                                value: normalizedAmount,
                                                                coinId: coinId,
                                                                payload: payload) {
                  let signedTx = RawTransactionSigner.sign(rawTx: rawTx,
                                                           privateKey: newPk.raw.toHexString())
                  observer.onNext(signedTx)
                } else {
                  observer.onError(SendViewModelError.invalidTransactionData)
                }
                observer.onCompleted()
              }
              return Disposables.create()
            } else {
              gasCoinId = (canPayCommissionWithBaseCoin) ? Coin.baseCoin().id! : coinId
              value = BigUInt(decimal: amount.decimalFromPIP()) ?? BigUInt(0)
            }
          } else {
            gasCoinId = (canPayCommissionWithBaseCoin) ? Coin.baseCoin().id! : coinId
            value = BigUInt(decimal: amount.decimalFromPIP()) ?? BigUInt(0)
          }
          if let rawTx: RawTransaction = self.rawTransaction(nonce: nonce,
                                                             gasCoinId: gasCoinId,
                                                             recipient: recipient,
                                                             value: value,
                                                             coinId: coinId,
                                                             payload: payload) {

            let pkString = newPk.raw.toHexString()
            let signedTx = RawTransactionSigner.sign(rawTx: rawTx, privateKey: pkString)
            observer.onNext(signedTx)
          } else {
            observer.onError(SendViewModelError.invalidTransactionData)
          }
          observer.onCompleted()
        } else {
          observer.onError(SendViewModelError.noPrivateKey)
          observer.onCompleted()
        }
        return Disposables.create()
      }
  }

  private func comissionText(recipient: String, for gas: Int, payloadData: Data? = nil) -> String {
    let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
    var commission = (RawTransactionType.sendCoin.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
    let balanceString = coinFormatter.formattedDecimal(with: commission)
    return balanceString + " " + (Coin.baseCoin().symbol ?? "")
  }

  // MARK: -

  func lastTransactionExplorerURL() -> URL? {
    guard nil != lastSentTransactionHash else {
      return nil
    }
    return URL(string: MinterExplorerBaseURL! + "/transactions/" + (lastSentTransactionHash ?? ""))
  }

  // MARK: -

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
    } else {
      notification = NotifiableError(title: "An Error Occurred".localized(),
                                     text: "Unable to send transaction".localized())
    }
    self.txErrorNotificationSubject.onNext(notification)
  }
}

extension SendViewModel {

  // MARK: - ViewModels

  func sendPopupViewModel(to: String, address: String, amount: Decimal) -> SendPopupViewModel {
    let viewModel = SendPopupViewModel()
    viewModel.amount = amount
    viewModel.coin = selectedCoin.value
    viewModel.username = to
    viewModel.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
    viewModel.popupTitle = "Confirm Transaction".localized()
    viewModel.buttonTitle = "Confirm".localized()
    viewModel.cancelTitle = "Cancel".localized()
    return viewModel
  }

  func sentViewModel(to: String, address: String) -> SentPopupViewModel {
    let viewModel = SentPopupViewModel(dependency: SentPopupViewModel.Dependency(recipientInfoService: self.dependency.recipientInfoService))
    viewModel.actionButtonTitle = "View Transaction".localized()
    viewModel.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
    viewModel.secondButtonTitle = "Close".localized()
    viewModel.username = to
    viewModel.title = "Success!".localized()
    return viewModel
  }
}

extension SendViewModel {
  enum CellIdentifierPrefix: String {
    case address = "UsernameTableViewCell_Address"
    case coin = "PickerTableViewCell_Coin"
    case amount = "AmountTextFieldTableViewCell_Amount"
    case fee = "TwoTitleTableViewCell_TransactionFee"
    case separator = "SeparatorTableViewCell"
    case blank = "BlankTableViewCell"
    case swtch = "SwitchTableViewCell"
    case button = "ButtonTableViewCell"
  }
} // swiftlint:disable:this file_length

extension SendViewModel: LUAutocompleteViewDataSource, LUAutocompleteViewDelegate {

  func autocompleteView(_ autocompleteView: LUAutocompleteView, elementsFor text: String, completion: @escaping ([String]) -> Void) {
    let term = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
    self.dependency.contactsService.contacts()
      .subscribe(onNext: { [weak self] (contacts) in
        let data = ((contacts.filter { (item) -> Bool in
          return (item.name ?? "").lowercased().starts(with: term) && (item.name ?? "").lowercased() != term.lowercased()
        })[safe: 0..<3])?.map { (item) -> String in
          return (item.name ?? "")
        } ?? []
        completion(data.sorted())
        self?.didProvideAutocomplete.onNext(())
    }).disposed(by: disposeBag)
  }

  func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect text: String) {
    self.recipientSubject.accept(text)
  }

}
