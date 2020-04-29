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

  var address: String?

  func titleFor(recipient: String) -> String? {
    return self.dependency.infoService.title(for: recipient)
  }

  func avatarURLFor(recipient: String) -> URL? {
    return self.dependency.infoService.avatarURL(for: recipient)
  }

  // MARK: -

  private var isLoading: Bool = false

  private var transactions = BehaviorSubject<[MinterExplorer.Transaction]>(value: [])
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewDidLoad = PublishSubject<Void>()
  private var didSelectItem = PublishSubject<IndexPath>()
  private var showTransaction = PublishSubject<MinterExplorer.Transaction?>()
  private var didTapShowAll = PublishSubject<Void>()

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
    var showNoTransactions: Observable<Bool>
    var showAllTransactions: Observable<Void>
  }

  struct Dependency {
    var transactionService: TransactionService
    var balanceService: BalanceService
    var infoService: RecipientInfoService
  }

  init(dependency: Dependency) {
    self.input = Input(transactions: transactions.asObserver(),
                       viewDidLoad: viewDidLoad.asObserver(),
                       didSelectItem: didSelectItem.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showTransaction: showTransaction.asObservable(),
                         showNoTransactions: sections.map({ (items) -> Bool in
                          return items.reduce(0) { $0 + $1.items.count } == 0
                         }),
                         showAllTransactions: didTapShowAll.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  func bind() {
    dependency.balanceService.account.map({ (account) -> String? in
      return account?.address
    }).filter { $0 != nil}.map{$0!}.subscribe(onNext: { [weak self] (address) in
      self?.address = address
      self?.loadTransactions(address: address)
    }).disposed(by: disposeBag)

    dependency.balanceService.balances().withLatestFrom(dependency.balanceService.account).subscribe(onNext: { [weak self] (account) in
      guard let address = account?.address else { return }
      self?.loadTransactions(address: address)
    }).disposed(by: disposeBag)

    Observable.combineLatest(viewDidLoad, transactions, self.dependency.infoService.isReady()).map({ (val) -> [MinterExplorer.Transaction] in
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

    if transactions.count > 0 {
      let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                                  identifier: "ButtonTableViewCell_Transactions")
      convertButton.buttonPattern = "blank"
      convertButton.title = "All Transactions".localized()
      convertButton.didTapButtonSubject.subscribe(didTapShowAll).disposed(by: disposeBag)
      cellItems.append(convertButton)
    } else {
      let noTransactions = BaseCellItem(reuseIdentifier: "noTransactionCell", identifier: "noTransactionCell")
      cellItems.append(noTransactions)
    }
    section1.items = cellItems
    sections.onNext([section1])
  }

  func loadTransactions(address: String) {
    dependency.transactionService
      .transactions(address: "Mx" + address.stripMinterHexPrefix(), filter: nil, page: 0)
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
  }

}
