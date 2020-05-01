//
//  TransactionViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterExplorer
import MinterMy

class TransactionViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let transaction: MinterExplorer.Transaction
  private let viewWillAppear = PublishSubject<Void>()
  private let viewDidDisappear = PublishSubject<Void>()
  private let sections = PublishSubject<[BaseTableSectionItem]>()
  private let didDismiss = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let copied = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: TransactionViewModel.Input!
  var output: TransactionViewModel.Output!
  var dependency: TransactionViewModel.Dependency!

  struct Input {
    var viewWillAppear: AnyObserver<Void>
    var viewDidDisappear: AnyObserver<Void>
  }

  struct Output {
    var didDismiss: Observable<Void>
    var sections: Observable<[BaseTableSectionItem]>
    var didTapShare: Observable<Void>
    var copied: Observable<Void>
  }

  struct Dependency {
    var recipientInfoService: RecipientInfoService
  }

  init(transaction: MinterExplorer.Transaction, dependency: Dependency) {
    self.transaction = transaction

    self.input = Input(viewWillAppear: viewWillAppear.asObserver(),
                       viewDidDisappear: viewDidDisappear.asObserver()
    )

    self.output = Output(didDismiss: didDismiss.asObservable(),
                         sections: sections.asObservable(),
                         didTapShare: didTapShare.asObservable(),
                         copied: copied.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {

    viewWillAppear.subscribe(onNext: { [weak self] (_) in
      self?.createSections()
    }).disposed(by: disposeBag)

    viewDidDisappear.subscribe(didDismiss).disposed(by: disposeBag)
  }

  private let fullDateFormatter = TransactionDateFormatter.transactionFullDateFormatter
  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  func createSections() {
    var section1 = BaseTableSectionItem(identifier: "TransactionSection", header: " ")

    var cellItems = [BaseCellItem]()
    if let txData = transaction.data as? SendCoinTransactionData {
      cellItems = sendTransactionItems(data: txData)
    } else if let txData = transaction.data as? MultisendCoinTransactionData {
      cellItems = multisendTransactionItems(data: txData)
    } else if let txData = transaction.data as? DelegatableUnbondableTransactionData {
      cellItems = delegateUnbondTransactionItems(data: txData)
    } else if let txData = transaction.data as? ConvertTransactionData {
      cellItems = convertTransactionItems(data: txData)
    } else if let txData = transaction.data as? RedeemCheckRawTransactionData {
      cellItems = redeemCheckTransactionItems(data: txData)
    } else {
      cellItems = systemTransactionItems(data: transaction.data)
    }

    section1.items = cellItems
    sections.onNext([section1])
  }

  func systemTransactionItems(data: TransactionData?) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                                identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

  func redeemCheckTransactionItems(data: RedeemCheckRawTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "From"
    if let address = transaction.from {
      from.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    from.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.from
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(from)

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterFrom")
    blank1.height = 23.0
    blank1.color = .white
    cellItems.append(blank1)

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = data.sender
    to.name = ""
    to.title = "To"
    if let address = data.sender {
      to.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.sender
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(to)

    let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterTo")
    blank2.height = 17.0
    blank2.color = .white
    cellItems.append(blank2)

    let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                identifier: "SeparatorTableViewCell")
    cellItems.append(separator1)

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                  identifier: "TransactionTwoColumnCell_AmountCoin")
    amountCoin.key1 = "Amount".localized()
    amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.value ?? 0.0,
                                                                 formatter: coinFormatter)
    amountCoin.key2 = "Coin".localized()
    amountCoin.value2 = data.coin
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                                identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

  func convertTransactionItems(data: ConvertTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "From"
    if let address = transaction.from {
      from.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    from.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.from
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(from)

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterFrom")
    blank1.height = 23.0
    blank1.color = .white
    cellItems.append(blank1)

    let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                identifier: "SeparatorTableViewCell")
    cellItems.append(separator1)

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)
      
      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                 identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let coins = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                             identifier: "TransactionTwoColumnCell_Coins")
    coins.key1 = "From Coin".localized()
    coins.value1 = data.fromCoin
    coins.key2 = "To Coin".localized()
    coins.value2 = data.toCoin
    cellItems.append(coins)

    let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_Coins")
    blank2.height = 5.0
    blank2.color = .white
    cellItems.append(blank2)

    let amounts = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                               identifier: "TransactionTwoColumnCell_Amounts")
    amounts.key1 = "Amount Spent".localized()
    amounts.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.valueToSell ?? 0.0,
                                                              formatter: coinFormatter)
    amounts.key2 = "Amount Received".localized()
    amounts.value2 = CurrencyNumberFormatter.formattedDecimal(with: data.valueToBuy ?? 0.0,
                                                              formatter: coinFormatter)
    cellItems.append(amounts)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_Amount")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                              identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

  func sendTransactionItems(data: SendCoinTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "From"
    if let address = transaction.from {
      from.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    from.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.from
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(from)

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterFrom")
    blank1.height = 6.0
    blank1.color = .white
    cellItems.append(blank1)

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = ""
    to.title = "To"
    if let address = transaction.data?.to {
      to.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      to.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.data?.to
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(to)

    let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterTo")
    blank2.height = 20.0
    blank2.color = .white
    cellItems.append(blank2)

    let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                identifier: "SeparatorTableViewCell")
    cellItems.append(separator1)

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                 identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                  identifier: "TransactionTwoColumnCell_AmountCoin")
    amountCoin.key1 = "Amount".localized()
    amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.amount ?? 0.0,
                                                                 formatter: coinFormatter)
    amountCoin.key2 = "Coin".localized()
    amountCoin.value2 = data.coin
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                              identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

  func delegateUnbondTransactionItems(data: DelegatableUnbondableTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "From"
    if let address = transaction.from {
      from.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    from.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.from
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(from)

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterFrom")
    blank1.height = 6.0
    blank1.color = .white
    cellItems.append(blank1)


    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = ""
    to.name = self.dependency.recipientInfoService.title(for: data.pubKey ?? "") ?? ""
    to.title = "To"
    to.address = data.pubKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.pubKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = transaction.type == .unbond ? UIImage(named: "UnbondIcon") : UIImage(named: "DelegateIcon")
    cellItems.append(to)

    let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterTo")
    blank2.height = 20.0
    blank2.color = .white
    cellItems.append(blank2)

    let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                identifier: "SeparatorTableViewCell")
    cellItems.append(separator1)

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                  identifier: "TransactionTwoColumnCell_AmountCoin")
    amountCoin.key1 = "Amount".localized()
    amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.value ?? 0.0,
                                                                 formatter: coinFormatter)
    amountCoin.key2 = "Coin".localized()
    amountCoin.value2 = data.coin
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)
    
    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                              identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

  func multisendTransactionItems(data: MultisendCoinTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "From"
    if let address = transaction.from {
      from.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      from.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    from.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = self?.transaction.from
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(from)

    let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AfterFrom")
    blank1.height = 6.0
    blank1.color = .white
    cellItems.append(blank1)

    for i in 0..<(data.values ?? []).count {
      guard let value = (data.values ?? [])[safe: i] else { continue }
      let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_address_\(i)")
      to.address = value.to
      to.name = ""
      to.title = "To"
      to.avatarURL = MinterMyAPIURL.avatarAddress(address: value.to).url()
      to.name = self.dependency.recipientInfoService.title(for: value.to) ?? ""
      to.didTapAddress.subscribe(onNext: { [weak self] (_) in
        UIPasteboard.general.string = value.to
        self?.copied.onNext(())
      }).disposed(by: disposeBag)
      cellItems.append(to)

      let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                    identifier: "TransactionTwoColumnCell_address_\(i)")
      amountCoin.key1 = "Amount".localized()
      amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: value.value,
                                                                   formatter: coinFormatter)
      amountCoin.key2 = "Coin".localized()
      amountCoin.value2 = value.coin
      cellItems.append(amountCoin)

      let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_address_\(i)")
      blank1.height = 10.0
      blank1.color = .white
      cellItems.append(blank1)

      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_address_\(i)")
      cellItems.append(separator1)
    }

    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      cellItems.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      cellItems.append(blank)

      let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank1.height = 10.0
      blank1.color = .white
      cellItems.append(blank1)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_2")
      cellItems.append(separator2)
    }

    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Timestamp")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      cellItems.append(dateItem)

      let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                          identifier: "BlankTableViewCell_Timestamp")
      blank4.height = 5.0
      blank4.color = .white
      cellItems.append(blank4)
    }

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    feeBlock.value1 = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    cellItems.append(feeBlock)

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                              identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    cellItems.append(shareButton)

    return cellItems
  }

}
