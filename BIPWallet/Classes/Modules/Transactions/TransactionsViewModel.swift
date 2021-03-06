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

  private var isLoading: Bool = false {
    didSet {
      isLoadingObservable.onNext(isLoading)
    }
  }
  private let isLoadingObservable = PublishSubject<Bool>()

  private var transactions = BehaviorSubject<[MinterExplorer.Transaction]>(value: [])
  private var sections = BehaviorSubject<[BaseTableSectionItem]>(value: [])
  private var didSelectItem = PublishSubject<IndexPath>()
  private var showTransaction = PublishSubject<MinterExplorer.Transaction?>()
  private var didTapShowAll = PublishSubject<Void>()
  private let didRefresh = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: TransactionsViewModel.Input!
  var output: TransactionsViewModel.Output!
  var dependency: TransactionsViewModel.Dependency!

  struct Input {
    var transactions: AnyObserver<[MinterExplorer.Transaction]>
    var didSelectItem: AnyObserver<IndexPath>
    var didRefresh: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var showTransaction: Observable<MinterExplorer.Transaction?>
    var showNoTransactions: Observable<Bool>
    var showAllTransactions: Observable<Void>
    var isLoading: Observable<Bool>
  }

  struct Dependency {
    var transactionService: TransactionService
    var balanceService: BalanceService
    var infoService: RecipientInfoService
  }

  init(dependency: Dependency) {

    self.input = Input(transactions: transactions.asObserver(),
                       didSelectItem: didSelectItem.asObserver(),
                       didRefresh: didRefresh.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showTransaction: showTransaction.asObservable(),
                         showNoTransactions: sections.map({ (items) -> Bool in
                          return items.reduce(0) { $0 + $1.items.count } == 0
                         }),
                         showAllTransactions: didTapShowAll.asObservable(),
                         isLoading: isLoadingObservable
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  func bind() {

    didRefresh.subscribe(onNext: { [weak self] (_) in
      guard let address = self?.address else { return }
      self?.loadTransactions(address: address, withoutLoader: false)
    }).disposed(by: disposeBag)

    Observable.combineLatest(dependency.balanceService.balances(), dependency.balanceService.account).debounce(.seconds(1), scheduler: MainScheduler.instance)
      .withLatestFrom(dependency.balanceService.account).subscribe(onNext: { [weak self] (account) in
      guard let address = account?.address else { return }
      self?.address = address
      self?.loadTransactions(address: address, withoutLoader: true)
    }).disposed(by: disposeBag)

    Observable.combineLatest(transactions, self.dependency.infoService.isReady()).map({ (val) -> [MinterExplorer.Transaction] in
      return val.0
    }).subscribe(onNext: { [weak self] (transactions) in
      self?.createSections(isLoading: self?.isLoading ?? false, transactions: transactions)
    }).disposed(by: disposeBag)

    //If contacts changed - reload cells
    self.dependency.infoService.didChangeInfo().throttle(.seconds(1), scheduler: MainScheduler.instance)
      .withLatestFrom(transactions).subscribe(onNext: { [weak self] (transactions) in
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
      let loadingCell = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell",
                                                 identifier: "LoadingTableViewCell")
      cellItems.append(loadingCell)
    }

    transactions.forEach { (transaction) in
      guard let txType = transaction.type else { return }

      let transactionCellItem: BaseCellItem?
      switch txType {
      case .sendCoin:
        transactionCellItem = self.sendTransactionItem(with: transaction)

      case .multisend:
        transactionCellItem = self.multisendTransactionItem(with: transaction)

      case .buyCoin, .sellCoin, .sellAllCoins:
        transactionCellItem = self.convertTransactionItem(with: transaction)

      case .delegate, .unbond:
        transactionCellItem = self.delegateTransactionItem(with: transaction)

      case .redeemCheck:
        transactionCellItem = self.redeemCheckTransactionItem(with: transaction)

      case .createCoin, .declareCandidacy, .setCandidateOnline,
           .setCandidateOffline, .createMultisigAddress, .editCandidate, .setHaltBlock,
           .recreateCoin, .changeCoinOwner, .editMultisigOwner, .priceVote, .editCandidatePublicKey:
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
      section1 = BaseTableSectionItem(identifier: "TransactionsSection_Empty",
                                      header: " ".localized())
      let noTransactions = BaseCellItem(reuseIdentifier: "noTransactionCell", identifier: "noTransactionCell")
      cellItems.append(noTransactions)
    }
    section1.items = cellItems
    sections.onNext([section1])
  }

  func loadTransactions(address: String, withoutLoader: Bool = false) {
    dependency.transactionService
      .transactions(address: "Mx" + address.stripMinterHexPrefix(), filter: nil, page: 0)
      .retry(.exponentialDelayed(maxCount: 3, initial: 1.0, multiplier: 2.0), scheduler: MainScheduler.instance, shouldRetry: nil)
      .do(onError: { (error) in
        self.isLoading = false
      }, onCompleted: {
        self.isLoading = false
      }, onSubscribe: { [weak self] in
        self?.isLoading = true
        let txs = (try? self?.transactions.value()) ?? []
        if !withoutLoader {
          self?.createSections(isLoading: self?.isLoading, transactions: txs)
        }
      }).subscribe(onNext: { [weak self] (transactions) in
        self?.isLoading = false
        self?.transactions.onNext(transactions[safe: 0..<10] ?? [])
      }).disposed(by: disposeBag)
  }

}
