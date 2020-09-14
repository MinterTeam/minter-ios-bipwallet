//
//  TransactionViewableViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 24.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import MinterMy

protocol TransactionViewableViewModel: class {
  func titleFor(recipient: String) -> String?
  func avatarURLFor(recipient: String) -> URL?
  var address: String? {get}
}

extension TransactionViewableViewModel {

  typealias TransactionItem = MinterExplorer.Transaction

  func sendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

    var signMultiplier = 1.0
    let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()
    let isSelf = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix() && address?.stripMinterHexPrefix() == (transaction.data?.to ?? "").stripMinterHexPrefix()

    var title = ""
    if hasAddress && !isSelf {
      signMultiplier = -1.0
      title = self.titleFor(recipient: transaction.data?.to ?? "") ?? transaction.data?.to ?? ""
    } else {
      title = self.titleFor(recipient: transaction.from ?? "") ?? transaction.from ?? ""
    }

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                   identifier: "TransactionCellItem_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title

    let avatarAddress = ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")
    transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: avatarAddress).url()

    if let avatarURL =  self.avatarURLFor(recipient: avatarAddress) {
      transactionCellItem.imageURL = avatarURL
    }

    if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
      transactionCellItem.coin = data.coin?.symbol
      let amount = (data.amount ?? 0) * Decimal(signMultiplier)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
    }
    transactionCellItem.type = !hasAddress || isSelf ? "Receive".localized() : "Send".localized()
    return transactionCellItem
  }

  func multisendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

    var signMultiplier = Decimal(1.0)
    let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()

    var title = ""
    if hasAddress {
      signMultiplier = -1.0
      let addr = transaction.data?.to ?? ""
      title = self.titleFor(recipient: addr) ?? addr
    } else {
      let addr = transaction.from ?? ""
      title = self.titleFor(recipient: addr) ?? addr
    }

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                   identifier: "MultisendTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title
    transactionCellItem.image = UIImage(named: "MultisendIcon")

    var values = [MultisendCoinTransactionData.MultisendValues]()

    if let data = transaction.data as? MultisendCoinTransactionData {
      if !hasAddress {
        values = data.values?.filter({ (val) -> Bool in
          return address?.stripMinterHexPrefix() == val.to.stripMinterHexPrefix()
        }) ?? []
      } else {
        values = data.values ?? []
      }
    }
    
    if Set(values.map{$0.coin.symbol}).count == 1 {
      let amount = values.reduce(0) { $0 + $1.value}
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: signMultiplier * amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
      transactionCellItem.coin = values.first?.coin.symbol
    } else {
      transactionCellItem.amount = ""
      transactionCellItem.coin = "Multiple Coins"
    }

    if (transactionCellItem.title?.count ?? 0) == 0 {
      transactionCellItem.title = self.titleFor(recipient: transaction.from ?? "") ?? transaction.from
    }
    
    transactionCellItem.type = "Multisend".localized()
    return transactionCellItem
  }

  func convertTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

    let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()

    var title = ""
    if hasAddress {
      let addr = transaction.data?.to ?? ""
      title = self.titleFor(recipient: addr) ?? ""
    } else {
      let addr = transaction.from ?? ""
      title = self.titleFor(recipient: addr) ?? ""
    }

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                   identifier: "ConvertTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title

    var arrowSign = " > "
    if #available(iOS 11.0, *) {
      arrowSign = "  ⟶  "
    }

    var amount: Decimal = 0.0
    if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
      transactionCellItem.title = (data.fromCoin?.symbol ?? "") + arrowSign + (data.toCoin?.symbol ?? "")
      amount = (data.valueToBuy ?? 0)
      transactionCellItem.coin = data.toCoin?.symbol
    } else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
      transactionCellItem.title = (data.fromCoin?.symbol ?? "") + arrowSign + (data.toCoin?.symbol ?? "")
      amount = (data.valueToBuy ?? 0)
      transactionCellItem.coin = data.toCoin?.symbol
    }
    transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                          formatter: CurrencyNumberFormatter.transactionFormatter)
    transactionCellItem.type = "Exchange".localized()
    transactionCellItem.image = UIImage(named: "ExchangeIcon")
    return transactionCellItem
  }

  func delegateTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                   identifier: "DelegateTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash

    let signMultiplier = transaction.type == .unbond ? 1.0 : -1.0
    if let data = transaction.data as? DelegatableUnbondableTransactionData {
      transactionCellItem.coin = data.coin?.symbol
      let amount = Decimal(signMultiplier) * (data.value ?? 0)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
      
      if let transactionData = transactionItem.data as? DelegateTransactionData, let publicKey = transactionData.pubKey {
        transactionCellItem.title = self.titleFor(recipient: publicKey) ?? publicKey
        transactionCellItem.imageURL = self.avatarURLFor(recipient: publicKey)
      } else {
        transactionCellItem.title = data.coin?.symbol ?? ""
      }
      transactionCellItem.type = transaction.type == .unbond ? "Unbond".localized() : "Delegate".localized()
      transactionCellItem.image = transaction.type == .unbond ? UIImage(named: "UnbondIcon") : UIImage(named: "DelegateIcon")
    }
    return transactionCellItem
  }

  func redeemCheckTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem

    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))

    var signMultiplier = 1.0
    let toAddress = "Mx" + (address ?? "").stripMinterHexPrefix()
    let title = toAddress

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                           identifier: "RedeemCheckTableViewCell\(sectionId)")
    transactionCellItem.type = "Redeem Check".localized()
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = (transaction.hash ?? title)
    transactionCellItem.image = UIImage(named: "redeemCheckIcon")

    if let data = transaction.data as? MinterExplorer.RedeemCheckRawTransactionData {
      let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()
      if !hasAddress {
        signMultiplier = -1.0
      }
      transactionCellItem.coin = data.coin?.symbol
      let amount = (data.value ?? 0) * Decimal(signMultiplier)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
    }
    return transactionCellItem
  }

  func systemTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem

    let sectionId = transaction.hash ?? String.random()

    let transactionCellItem = TransactionCellItem(reuseIdentifier: "TransactionCell",
                                                   identifier: "SystemTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    guard let txType = transaction.type else { return nil }
    transactionCellItem.title = transaction.hash
    transactionCellItem.image = UIImage(named: "systemTransactionImage")

    switch txType {
    case .createCoin:
      transactionCellItem.type = "Create Coin"
      if let data = transaction.data as? CreateCoinTransactionData {
        transactionCellItem.title = data.name ?? data.symbol ?? ""
        transactionCellItem.coin = data.symbol ?? ""
        transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: data.initialAmount ?? 0.0,
                                                                              formatter: CurrencyNumberFormatter.transactionFormatter)
        transactionCellItem.image = UIImage(named: "CreateCoin")
      }

    case .createMultisig:
      transactionCellItem.type = "Create Multisig Address"
      if let data = transaction.data as? CreateMultisigAddressTransactionData {
        transactionCellItem.title = TransactionTitleHelper.title(from: data.multisigAddress ?? "")
        transactionCellItem.image = UIImage(named: "MultisigIcon")
      }
    case .declare:
      transactionCellItem.type = "Declare Candidacy"
      if let data = transaction.data as? DeclareCandidacyTransactionData {
        transactionCellItem.title = TransactionTitleHelper.title(from: data.pubKey ?? "")
        transactionCellItem.image = UIImage(named: "SystemIcon")
        transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: -(data.stake ?? 0.0),
                                                                              formatter: CurrencyNumberFormatter.transactionFormatter)
        transactionCellItem.coin = data.coin?.symbol
      }
    case .editCandidate:
      transactionCellItem.type = "Edit Candidate"
      if let data = transaction.data as? EditCandidateTransactionData {
        transactionCellItem.title = TransactionTitleHelper.title(from: data.pubKey ?? "")
        transactionCellItem.image = UIImage(named: "SystemIcon")
      }
    case .setCandidateOffline:
      transactionCellItem.type = "Set Candidate Offline"
      if let data = transaction.data as? SetCandidateBaseTransactionData {
        transactionCellItem.title = TransactionTitleHelper.title(from: data.pubKey ?? "")
        transactionCellItem.image = UIImage(named: "SystemIcon")
      }
    case .setCandidateOnline:
      transactionCellItem.type = "Set Candidate Online"
      if let data = transaction.data as? SetCandidateBaseTransactionData {
        transactionCellItem.title = TransactionTitleHelper.title(from: data.pubKey ?? "")
        transactionCellItem.image = UIImage(named: "SystemIcon")
      }

    default:
      break
    }
    return transactionCellItem
  }

}
