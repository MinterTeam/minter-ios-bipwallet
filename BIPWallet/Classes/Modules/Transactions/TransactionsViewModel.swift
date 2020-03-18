//
//  TransactionsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

class TransactionsViewModel: BaseViewModel, ViewModel, TransactionViewableViewModel {

  // MARK: - TransactionViewableViewModel

  var addressBook: [String: String] = [:]
  var address: String
  private var isLoading: Bool = false

  // MARK: -

  private var transactions = BehaviorSubject<[MinterExplorer.Transaction]>(value: [])
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewDidLoad = PublishSubject<Void>()
  private var didSelectItem = PublishSubject<IndexPath>()
  private var showTransaction = PublishSubject<MinterExplorer.Transaction?>()

  // MARK: - ViewModel

  var input: TransactionsViewModel.Input!
  var output: TransactionsViewModel.Output!
  var dependency: TransactionsViewModel.Dependency!

  struct Input {
    var transactions: AnyObserver<[MinterExplorer.Transaction]>
    var viewDidLoad: AnyObserver<Void>
    var didSelectItem: AnyObserver<IndexPath>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var showTransaction: Observable<MinterExplorer.Transaction?>
  }

  struct Dependency {
    var transactionService: TransactionService
  }

  init(address: String, dependency: Dependency) {
    self.input = Input(transactions: transactions.asObserver(),
                       viewDidLoad: viewDidLoad.asObserver(),
                       didSelectItem: didSelectItem.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showTransaction: showTransaction.asObservable()
    )

    self.dependency = dependency
    self.address = address

    super.init()

    bind()
  }

  func bind() {
    dependency.transactionService
      .transactions(address: "Mx" + address, page: 0)
      .do(onNext: { (txs) in
        
      }, onError: { (error) in
        self.isLoading = false
      }, onCompleted: {
        self.isLoading = false
      }, onSubscribe: { [weak self] in
        self?.isLoading = true
        let txs = (try? self?.transactions.value()) ?? []
        self?.createSections(isLoading: self?.isLoading, transactions: txs)
      })
      .subscribe(onNext: { [weak self] (transactions) in
        self?.isLoading = false
        self?.transactions.onNext(transactions[safe: 0..<10] ?? [])
      }).disposed(by: disposeBag)

    Observable.combineLatest(viewDidLoad, transactions).map({ (val) -> [MinterExplorer.Transaction] in
      return val.1
    }).subscribe(onNext: { [weak self] (transactions) in
      self?.createSections(isLoading: self?.isLoading ?? false, transactions: transactions)
    }).disposed(by: disposeBag)

    didSelectItem.map({ (indexPath) -> IndexPath in
      return IndexPath(row: indexPath.row/2, section: indexPath.section)
    }).map({ (indexPath) -> MinterExplorer.Transaction? in
      return try? self.transactions.value()[safe: indexPath.row]
    }).filter({ (transaction) -> Bool in
      return nil != transaction
    }).subscribe(showTransaction).disposed(by: disposeBag)
  }

  // MARK: -

  func createSections(isLoading: Bool? = false, transactions: [MinterExplorer.Transaction]) {
    var section1 = BaseTableSectionItem(identifier: "TransactionsSection",
                                        header: "LATEST TRANSACTIONS".localized())
    var cellItems = [BaseCellItem]()

    if isLoading ?? false {
      let loadingCell = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell", identifier: "LoadingTableViewCell")
      cellItems.append(loadingCell)
    }

    transactions.forEach { (transaction) in
      guard let txType = transaction.type else { return }

      let transactionCellItem: BaseCellItem?
      switch txType {
      case .send:
        transactionCellItem = self.sendTransactionItem(with: transaction)

      case .multisend:
        transactionCellItem = self.multisendTransactionItem(with: transaction)

      case .buy, .sell, .sellAll:
        transactionCellItem = self.convertTransactionItem(with: transaction)

      case .delegate, .unbond:
        transactionCellItem = self.delegateTransactionItem(with: transaction)

      case .redeemCheck:
        transactionCellItem = self.redeemCheckTransactionItem(with: transaction)

      case .create, .declare, .setCandidateOnline,
           .setCandidateOffline, .createMultisig, .editCandidate:
        transactionCellItem = self.systemTransactionItem(with: transaction)
      }

      guard let cellItem = transactionCellItem else { return }

      cellItems.append(cellItem)

      let key = transaction.txn != nil ? String(transaction.txn!) : String.random()
      let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(key)")
      cellItems.append(separator)
    }

    let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                                identifier: "ButtonTableViewCell_Transactions")
    convertButton.buttonPattern = "blank"
    convertButton.title = "All Transactions".localized()

    cellItems.append(convertButton)
    section1.items = cellItems
    sections.onNext([section1])
  }

}
