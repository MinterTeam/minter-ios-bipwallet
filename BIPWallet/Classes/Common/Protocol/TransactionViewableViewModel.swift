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
  var addressBook: [String: String] {get set}
  var address: String? {get}
}

extension TransactionViewableViewModel {

  typealias TransactionItem = MinterExplorer.Transaction

  func sendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

    var signMultiplier = 1.0
    let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()

    var title = ""
    if hasAddress {
      title = transaction.data?.to ?? ""
      signMultiplier = -1.0
    } else {
      title = transaction.from ?? ""
    }

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                   identifier: "TransactionCellItem_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title
    let avatarAddress = ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")
    transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: avatarAddress).url()
    if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
      transactionCellItem.coin = data.coin
      let amount = (data.amount ?? 0) * Decimal(signMultiplier)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
    }
    transactionCellItem.type = "Send".localized()
    return transactionCellItem
  }

  func multisendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem
    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

    var signMultiplier = 1.0
    let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()

    var title = ""
    if hasAddress {
      title = transaction.data?.to ?? ""
      signMultiplier = -1.0
    } else {
      title = transaction.from ?? ""
    }

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                   identifier: "MultisendTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title
    let txAddress = ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")
    transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: txAddress).url()

    if let data = transaction.data as? MultisendCoinTransactionData {
      if let val = data.values?.filter({ (val) -> Bool in
        return address?.stripMinterHexPrefix() == val.to.stripMinterHexPrefix()
      }), val.count > 0 {
        if let payload = val.first {
          transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with:payload.value,
                                                                                formatter: CurrencyNumberFormatter.transactionFormatter)
          transactionCellItem.coin = payload.coin
          if hasAddress {
            transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: payload.to).url()
          } else {
            if let from = transaction.from {
              transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: from).url()
            }
          }
        }
      }

      if (transactionCellItem.title?.count ?? 0) == 0 {
        transactionCellItem.title = transaction.from
        if let from = transaction.from {
          transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: from).url()
        }
      }
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
      title = transaction.data?.to ?? ""
    } else {
      title = transaction.from ?? ""
    }

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                   identifier: "ConvertTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = title

    var arrowSign = " > "
    if #available(iOS 11.0, *) {
      arrowSign = "  ⟶  "
    }

    var amount: Decimal = 0.0
    if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
      transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
      amount = (data.valueToBuy ?? 0)
      transactionCellItem.coin = data.toCoin
    } else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
      transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
      amount = (data.valueToBuy ?? 0)
      transactionCellItem.coin = data.toCoin
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

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                   identifier: "DelegateTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash

    let signMultiplier = transaction.type == .unbond ? 1.0 : -1.0
    if let data = transaction.data as? DelegatableUnbondableTransactionData {
      transactionCellItem.coin = data.coin
      let amount = Decimal(signMultiplier) * (data.value ?? 0)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
      transactionCellItem.title = data.coin ?? ""
      transactionCellItem.type = transaction.type == .unbond ? "Unbond".localized() : "Delegate".localized()
      transactionCellItem.image = transaction.type == .unbond ? UIImage(named: "unbondImage") : UIImage(named: "delegateImage")
    }
    return transactionCellItem
  }

  func redeemCheckTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem

    let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))

    var signMultiplier = 1.0
    let toAddress = "Mx" + (address ?? "").stripMinterHexPrefix()
    let title = toAddress

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                           identifier: "RedeemCheckTableViewCell\(sectionId)")
    transactionCellItem.type = "Check".localized()
    transactionCellItem.txHash = transaction.hash
    transactionCellItem.title = (transaction.hash ?? title)
    transactionCellItem.image = UIImage(named: "redeemCheckImage")

    if let data = transaction.data as? MinterExplorer.RedeemCheckRawTransactionData {
      let hasAddress = address?.stripMinterHexPrefix() == (transaction.from ?? "").stripMinterHexPrefix()
      if !hasAddress {
        signMultiplier = -1.0
      }
      transactionCellItem.coin = data.coin
      let amount = (data.value ?? 0) * Decimal(signMultiplier)
      transactionCellItem.amount = CurrencyNumberFormatter.formattedDecimal(with: amount,
                                                                            formatter: CurrencyNumberFormatter.transactionFormatter)
    }
    return transactionCellItem
  }

  func systemTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
    let transaction = transactionItem

    let sectionId = transaction.hash ?? String.random()

    let transactionCellItem = TransactionCellItem1(reuseIdentifier: "TransactionCell",
                                                   identifier: "SystemTransactionTableViewCell_\(sectionId)")
    transactionCellItem.txHash = transaction.hash
    guard let txType = transaction.type else { return nil }

    switch txType {
    case .create:
      transactionCellItem.type = "Create Coin"
    case .createMultisig:
      transactionCellItem.type = "Create Multisig"
    case .declare:
      transactionCellItem.type = "Declare Candidate"
    case .editCandidate:
      transactionCellItem.type = "Edit Candidate"
    case .setCandidateOffline:
      transactionCellItem.type = "Set Candidate Offline"
    case .setCandidateOnline:
      transactionCellItem.type = "Set Candidate Online"
    default:
      break
    }
    transactionCellItem.title = transaction.hash
    transactionCellItem.image = UIImage(named: "systemTransactionImage")
    return transactionCellItem
  }

}
