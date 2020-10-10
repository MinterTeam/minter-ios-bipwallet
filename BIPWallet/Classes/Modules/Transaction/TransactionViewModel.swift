//
//  TransactionViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer
import MinterMy

class TransactionViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private let transaction: MinterExplorer.Transaction
  private let address: String
  private let viewWillAppear = PublishSubject<Void>()
  private let viewDidDisappear = PublishSubject<Void>()
  private let sections = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
  private let didDismiss = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let copied = PublishSubject<Void>()
  private let showExplorer = PublishSubject<String?>()

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
    var showExplorer: Observable<String?>
  }

  struct Dependency {
    var recipientInfoService: RecipientInfoService
  }

  init(transaction: MinterExplorer.Transaction, address: String, dependency: Dependency) {
    self.transaction = transaction
    self.address = address

    self.input = Input(viewWillAppear: viewWillAppear.asObserver(),
                       viewDidDisappear: viewDidDisappear.asObserver()
    )

    self.output = Output(didDismiss: didDismiss.asObservable(),
                         sections: sections.asObservable(),
                         didTapShare: didTapShare.asObservable(),
                         copied: copied.asObservable(),
                         showExplorer: showExplorer.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {

    createSections()

    viewDidDisappear.subscribe(didDismiss).disposed(by: disposeBag)
  }

  private let fullDateFormatter = TransactionDateFormatter.transactionFullDateFormatter
  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  func createSections() {
    var section1 = BaseTableSectionItem(identifier: "TransactionSection", header: " ")

    var cellItems = [BaseCellItem]()
    if let txData = transaction.data as? MinterExplorer.SendCoinTransactionData {
      cellItems = sendTransactionItems(data: txData)
    } else if let txData = transaction.data as? MultisendCoinTransactionData {
      cellItems = multisendTransactionItems(data: txData)
    } else if let txData = transaction.data as? DelegatableUnbondableTransactionData {
      cellItems = delegateUnbondTransactionItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.ConvertTransactionData {
      cellItems = convertTransactionItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
      cellItems = sellAllTransactionItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.RedeemCheckRawTransactionData {
      cellItems = redeemCheckTransactionItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.CreateMultisigAddressTransactionData {
      cellItems = createMultisigAddressItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.CreateCoinTransactionData {
      cellItems = createCoinItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.CreateCoinTransactionData {
      cellItems = createCoinItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.DeclareCandidacyTransactionData {
      cellItems = declareCandidacyItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.EditCandidateTransactionData {
      cellItems = editCandidateItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.EditCandidatePublicKeyTransactionData {
      cellItems = editCandidatePublicKeyItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.SetCandidateBaseTransactionData {
      cellItems = setCandidateOnlineOfflineItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.SetHaltBlockTransactionData {
      cellItems = setHaltBlockItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.PriceVoteTransactionData {
      cellItems = priceVoteItems(data: txData)
    } else if let txData = transaction.data as? MinterExplorer.ChangeCoinOwnerTransactionData {
      cellItems = changeCoinOwnerItems(data: txData)
    } else {
      cellItems = systemTransactionItems(data: transaction.data)
    }

    section1.items = cellItems
    sections.onNext([section1])
  }

  func systemTransactionItems(data: MinterExplorer.TransactionData?) -> [BaseCellItem] {
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

    cellItems.append(feeBlock())

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

    return cellItems
  }

  func redeemCheckTransactionItems(data: MinterExplorer.RedeemCheckRawTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = data.sender
    to.name = ""
    to.title = "Check Issuer"
    if let address = data.sender {
      to.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
      to.name = self.dependency.recipientInfoService.title(for: address) ?? ""
    }
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.sender
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    cellItems.append(to)

    let from = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_From")
    from.address = transaction.from
    from.name = ""
    from.title = "To"
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
    blank1.height = 16.0
    blank1.color = .white
    cellItems.append(blank1)

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
    amountCoin.value2 = data.coin?.symbol
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    cellItems.append(feeBlock())

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

    return cellItems
  }

  func convertTransactionItems(data: MinterExplorer.ConvertTransactionData) -> [BaseCellItem] {
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
    coins.value1 = data.fromCoin?.symbol
    coins.key2 = "To Coin".localized()
    coins.value2 = data.toCoin?.symbol
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

    cellItems.append(feeBlock())

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

    return cellItems
  }

  func sellAllTransactionItems(data: MinterExplorer.SellAllCoinsTransactionData) -> [BaseCellItem] {
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
    coins.value1 = data.fromCoin?.symbol
    coins.key2 = "To Coin".localized()
    coins.value2 = data.toCoin?.symbol
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

    cellItems.append(feeBlock())

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

    return cellItems
  }

  func sendTransactionItems(data: MinterExplorer.SendCoinTransactionData) -> [BaseCellItem] {
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
    amountCoin.value2 = data.coin?.symbol
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    cellItems.append(feeBlock())

    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

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
    to.name = self.dependency.recipientInfoService.title(for: data.publicKey ?? "") ?? ""
    to.title = "To"
    to.address = data.publicKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.publicKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = transaction.type == .unbond ? UIImage(named: "UnbondIcon") : UIImage(named: "DelegateIcon")
    if let publicKey = data.publicKey {
      to.avatarURL = self.dependency.recipientInfoService.avatarURL(for: publicKey)
    }
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
    amountCoin.key1 = "Stake".localized()
    amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.value ?? 0.0,
                                                                 formatter: coinFormatter)
    amountCoin.key2 = "Coin".localized()
    amountCoin.value2 = data.coin?.symbol
    cellItems.append(amountCoin)

    let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_AmountCoin")
    blank3.height = 5.0
    blank3.color = .white
    cellItems.append(blank3)

    cellItems.append(feeBlock())
    
    let blank4 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                        identifier: "BlankTableViewCell_BeforeShare")
    blank4.height = 10.0
    blank4.color = .white
    cellItems.append(blank4)

    cellItems.append(shareTransaction())

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

    cellItems.append(blankItem(height: 6))

    if self.address != transaction.from {
      let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                          identifier: "TransactionAddressCell_To")
      to.address = self.address
      to.name = self.dependency.recipientInfoService.title(for: self.address) ?? ""
      to.title = "To"
      to.didTapAddress.subscribe(onNext: { [weak self] (_) in
        UIPasteboard.general.string = self?.address
        self?.copied.onNext(())
      }).disposed(by: disposeBag)
      to.avatar = transaction.type == .unbond ? UIImage(named: "UnbondIcon") : UIImage(named: "DelegateIcon")
      to.avatarURL = self.dependency.recipientInfoService.avatarURL(for: self.address)
      cellItems.append(to)
    }

    cellItems.append(blankItem(height: 10.0))

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    var values = [MultisendCoinTransactionData.MultisendValues]()
    if let data = transaction.data as? MultisendCoinTransactionData {
      if address.stripMinterHexPrefix() != (transaction.from ?? "").stripMinterHexPrefix() {
        values = data.values?.filter({ (val) -> Bool in
          return address.stripMinterHexPrefix() == val.to.stripMinterHexPrefix()
        }) ?? []
      } else {
        values = data.values ?? []
      }
    }

    if Set(values.map{$0.coin.symbol}).count == 1 {
      let amount = values.reduce(0) { $0 + $1.value}

      let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                    identifier: "TransactionTwoColumnCell_AmountCoin")
      amountCoin.key1 = "Stake".localized()
      amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                   formatter: coinFormatter)
      amountCoin.key2 = "Coin".localized()
      amountCoin.value2 = values.first?.coin.symbol
      cellItems.append(amountCoin)
    }

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }
  
  func createMultisigAddressItems(data: CreateMultisigAddressTransactionData) -> [BaseCellItem] {
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

    cellItems.append(blankItem(height: 16))

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
    }

    let address = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                              identifier: "TransactionKeyValueCell_Address")
    address.key = "Multisig Address".localized()
    address.value = data.multisigAddress
    cellItems.append(address)

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func createCoinItems(data: CreateCoinTransactionData) -> [BaseCellItem] {
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

    cellItems.append(blankItem(height: 16))

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    let coin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                            identifier: "TransactionTwoColumnCell_\(String.random())")
    coin.key1 = "Coin Name".localized()
    coin.value1 = data.name
    coin.key2 = "Coin Symbol".localized()
    coin.value2 = data.symbol
    cellItems.append(coin)

    let amount = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                              identifier: "TransactionTwoColumnCell_\(String.random())")
    amount.key1 = "Initial Amount".localized()
    amount.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.initialAmount ?? 0.0,
                                                             formatter: coinFormatter)
    amount.key2 = "initial Reserve".localized()
    amount.value2 = CurrencyNumberFormatter.formattedDecimal(with: data.initialReserve ?? 0.0,
                                                             formatter: coinFormatter)
    cellItems.append(amount)

    let ratio = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                              identifier: "TransactionTwoColumnCell_\(String.random())")
    ratio.key1 = "Constant Reserve Ratio".localized()

    ratio.value1 = "\(data.constantReserveRatio ?? 0)%"

    ratio.key2 = "Max Supply".localized()
    ratio.value2 = CurrencyNumberFormatter.formattedDecimal(with: data.maxSupply ?? 0.0,
                                                            formatter: coinFormatter)
    if (data.maxSupply ?? 0.0) == Decimal(pow(10, 15)) {
      ratio.value2 = "10¹⁵ (max)"
    }
    cellItems.append(ratio)

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func declareCandidacyItems(data: DeclareCandidacyTransactionData) -> [BaseCellItem] {
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

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = self.dependency.recipientInfoService.title(for: data.publicKey ?? "") ?? ""
    to.title = "To"
    to.address = data.publicKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.publicKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = UIImage(named: "SystemIcon")
    cellItems.append(to)

    cellItems.append(blankItem(height: 16))

    let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                identifier: "SeparatorTableViewCell_\(String.random())")

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    let coin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                            identifier: "TransactionTwoColumnCell_\(String.random())")
    coin.key1 = "Commission".localized()
    coin.value1 = (data.commission != nil) ? "\(data.commission ?? 0)%" : ""
    coin.key2 = "Coin".localized()
    coin.value2 = data.coin?.symbol
    cellItems.append(coin)

    let stake = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                            identifier: "TransactionTwoColumnCell_\(String.random())")
    stake.key1 = "Stake".localized()
    stake.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.stake ?? 0.0,
                                                            formatter: coinFormatter)
    stake.key2 = "".localized()
    stake.value2 = nil
    cellItems.append(stake)

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func editCandidateItems(data: EditCandidateTransactionData) -> [BaseCellItem] {
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

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = self.dependency.recipientInfoService.title(for: data.publicKey ?? "") ?? ""
    to.title = "To"
    to.address = data.publicKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.publicKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = UIImage(named: "SystemIcon")
    cellItems.append(to)

    cellItems.append(blankItem(height: 16))

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
    }

    let rewardAddress = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                  identifier: "TransactionKeyValueCell_Reward")
    rewardAddress.key = "Reward Address".localized()
    rewardAddress.value = data.rewardAddress
    cellItems.append(rewardAddress)

    let ownerAddress = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                  identifier: "TransactionKeyValueCell_Owner")
    ownerAddress.key = "Owner Address".localized()
    ownerAddress.value = data.ownerAddress
    cellItems.append(ownerAddress)

    let controlAddress = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                  identifier: "TransactionKeyValueCell_Control")
    controlAddress.key = "Control Address".localized()
    controlAddress.value = data.controlAddress
    cellItems.append(controlAddress)

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func editCandidatePublicKeyItems(data: EditCandidatePublicKeyTransactionData) -> [BaseCellItem] {
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

    cellItems.append(blankItem(height: 16))

    cellItems.append(contentsOf: payloadBlock())

    if let date = transaction.date {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
    }

    let publicKey = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                  identifier: "TransactionKeyValueCell_PublicKey")
    publicKey.key = "Public Key".localized()
    publicKey.value = data.publicKey
    cellItems.append(publicKey)

    let newPublicKey = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                  identifier: "TransactionKeyValueCell_NewPublicKey")
    newPublicKey.key = "New Public Key".localized()
    newPublicKey.value = data.newPublicKey
    cellItems.append(newPublicKey)

    cellItems.append(blankItem(height: 5))

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func setCandidateOnlineOfflineItems(data: SetCandidateBaseTransactionData) -> [BaseCellItem] {
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

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = self.dependency.recipientInfoService.title(for: data.publicKey ?? "") ?? ""
    to.title = "To"
    to.address = data.publicKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.publicKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = UIImage(named: "SystemIcon")
    cellItems.append(to)

    cellItems.append(blankItem(height: 16))

    cellItems.append(contentsOf: payloadBlock())

    if transaction.date != nil {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }
  
  func setHaltBlockItems(data: SetHaltBlockTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    cellItems.append(fromBlock())

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = self.dependency.recipientInfoService.title(for: data.publicKey ?? "") ?? ""
    to.title = "To"
    to.address = data.publicKey
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.publicKey
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = UIImage(named: "SystemIcon")
    cellItems.append(to)

    cellItems.append(blankItem(height: 16))

    let haltBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                            identifier: "TransactionTwoColumnCell_\(String.random())")
    haltBlock.key1 = "Height".localized()
    haltBlock.value1 = "\(data.height ?? 0)"
    cellItems.append(haltBlock)

    cellItems.append(contentsOf: payloadBlock())

    if transaction.date != nil {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func priceVoteItems(data: PriceVoteTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    cellItems.append(fromBlock())

    cellItems.append(blankItem(height: 16))

    let amountCoin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                  identifier: "TransactionTwoColumnCell_AmountCoin")
    amountCoin.key1 = "Price".localized()
    amountCoin.value1 = CurrencyNumberFormatter.formattedDecimal(with: data.price ?? 0.0,
                                                                 formatter: coinFormatter)
    cellItems.append(amountCoin)

    cellItems.append(contentsOf: payloadBlock())

    if transaction.date != nil {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  func changeCoinOwnerItems(data: ChangeCoinOwnerTransactionData) -> [BaseCellItem] {
    var cellItems = [BaseCellItem]()

    cellItems.append(fromBlock())

    let to = TransactionAddressCellItem(reuseIdentifier: "TransactionAddressCell",
                                        identifier: "TransactionAddressCell_To")
    to.address = transaction.data?.to
    to.name = self.dependency.recipientInfoService.title(for: data.owner ?? "") ?? ""
    to.title = "To"
    to.address = data.owner
    to.didTapAddress.subscribe(onNext: { [weak self] (_) in
      UIPasteboard.general.string = data.owner
      self?.copied.onNext(())
    }).disposed(by: disposeBag)
    to.avatar = UIImage(named: "SystemIcon")
    cellItems.append(to)

    cellItems.append(blankItem(height: 16))

    let coin = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                  identifier: "TransactionTwoColumnCell_AmountCoin")
    coin.key1 = "Coin".localized()
    coin.value1 = data.coinSymbol
    cellItems.append(coin)

    cellItems.append(contentsOf: payloadBlock())

    if transaction.date != nil {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      cellItems.append(separator1)

      cellItems.append(contentsOf: dateBlock())
      cellItems.append(blankItem(height: 5.0))
    }

    cellItems.append(feeBlock())

    cellItems.append(blankItem(height: 10))

    cellItems.append(shareTransaction())

    return cellItems
  }

  // MARK: - Blocks

  func fromBlock() -> TransactionAddressCellItem {
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
    return from
  }

  func shareTransaction() -> ButtonTableViewCellItem {
    let shareButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                              identifier: "ButtonTableViewCell_ShareTransactions")
    shareButton.buttonPattern = "blank"
    shareButton.title = "Share Transaction".localized()
    shareButton.didTapButtonSubject.subscribe(didTapShare).disposed(by: disposeBag)
    return shareButton
  }

  func feeBlock() -> TransactionTwoColumnCellItem {
    let feeBlock = TransactionTwoColumnCellItem(reuseIdentifier: "TransactionTwoColumnCell",
                                                identifier: "TransactionTwoColumnCell_FeeBlock")
    feeBlock.key1 = "Fee".localized()
    if transaction.feeCoin?.symbol != Coin.baseCoin().symbol! {
      var feeString = ""
      feeString = (transaction.feeCoin?.symbol ?? "")
      feeString += " ("
      feeString += CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                            formatter: coinFormatter)
      feeString += " "
      feeString += Coin.baseCoin().symbol!
      feeString += ")"
      feeBlock.value1 = feeString
    } else {
      var feeString = CurrencyNumberFormatter.formattedDecimal(with: transaction.fee ?? 0.0,
                                                               formatter: coinFormatter)
      feeString += " "
      feeString += Coin.baseCoin().symbol!
      feeBlock.value1 = feeString
    }

    feeBlock.key2 = "Block".localized()
    feeBlock.value2 = String(transaction.block ?? 0)
    feeBlock.value2Interactable = true
    feeBlock.value2DidTap.map {_ in return self.transaction.hash }
      .asDriver(onErrorJustReturn: nil)
      .drive(showExplorer).disposed(by: disposeBag)

    return feeBlock
  }

  func payloadBlock() -> [BaseCellItem] {
    var payloadCells = [BaseCellItem]()
    if let payload = transaction.payload?.base64Decoded(), payload.count > 0 {
      let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                  identifier: "SeparatorTableViewCell_\(String.random())")
      payloadCells.append(separator1)
      let payloadItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                    identifier: "TransactionKeyValueCell_Payload")
      payloadItem.key = "Payload".localized()
      payloadItem.value = payload
      payloadCells.append(payloadItem)

      let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                         identifier: "BlankTableViewCell_\(String.random())")
      blank.height = 10
      payloadCells.append(blank)

      let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(String.random())")
      payloadCells.append(separator2)
    }
    return payloadCells
  }
  
  func blankItem(height: CGFloat = 10.0, color: UIColor = .white) -> BlankTableViewCellItem {
    let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
                                       identifier: "BlankTableViewCell_address_\(String.random())")
    blank.height = height
    blank.color = color
    return blank
  }

  func dateBlock() -> [BaseCellItem] {
    var block = [BaseCellItem]()
    if let date = transaction.date {
      let dateItem = TransactionKeyValueCellItem(reuseIdentifier: "TransactionKeyValueCell",
                                                 identifier: "TransactionKeyValueCell_\(String.random())")
      dateItem.key = "Timestamp".localized()
      dateItem.value = fullDateFormatter.string(from: date)
      block.append(dateItem)
    }
    return block
  }

}
