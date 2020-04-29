//
//  AllTransactionsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MinterCore
import MinterExplorer
import AFDateHelper

class AllTransactionsViewModel: BaseViewModel, ViewModel, TransactionViewableViewModel {

  private var sectionTitleDateFormatter = DateFormatter()
  private var sectionTitleDateFullFormatter = DateFormatter()

  // MARK: - TransactionViewableViewModel

  var address: String?

  func titleFor(recipient: String) -> String? {
    return self.dependency.recipientInfoService.title(for: recipient)
  }

  func avatarURLFor(recipient: String) -> URL? {
    self.dependency.recipientInfoService.avatarURL(for: recipient)
  }

  private var isLoading = true
  private var stopSearching = false
  private var isLoadingObservable = PublishSubject<Bool>()
  private var page = 1
  private var existingSections = [BaseTableSectionItem]()
  private var filter: TransactionServiceFilter?

  // MARK: -

  private let transactions = BehaviorSubject<[MinterExplorer.Transaction]>(value: [])
  private let sections = PublishSubject<[BaseTableSectionItem]>()
  private let viewWillAppear = PublishSubject<Void>()
  private let didSelectItem = PublishSubject<IndexPath>()
  private let modelSelected = PublishSubject<BaseCellItem?>()
  private let showTransaction = PublishSubject<MinterExplorer.Transaction?>()
  private let didTapShowAll = PublishSubject<Void>()
  private let willDisplayCell = PublishSubject<WillDisplayCellEvent>()
  private let filterAllTaped = PublishSubject<Void>()
  private let filterIncomingTaped = PublishSubject<Void>()
  private let filterOutgoingTaped = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: AllTransactionsViewModel.Input!
  var output: AllTransactionsViewModel.Output!
  var dependency: AllTransactionsViewModel.Dependency!

  struct Input {
    var transactions: AnyObserver<[MinterExplorer.Transaction]>
    var viewWillAppear: AnyObserver<Void>
    var didSelectItem: AnyObserver<IndexPath>
    var willDisplayCell: AnyObserver<WillDisplayCellEvent>
    var filterAllTaped: AnyObserver<Void>
    var filterIncomingTaped: AnyObserver<Void>
    var filterOutgoingTaped: AnyObserver<Void>
    var modelSelected: AnyObserver<BaseCellItem?>
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
    var recipientInfoService: RecipientInfoService
  }

  init(dependency: Dependency) {
    super.init()

    self.input = Input(transactions: transactions.asObserver(),
                       viewWillAppear: viewWillAppear.asObserver(),
                       didSelectItem: didSelectItem.asObserver(),
                       willDisplayCell: willDisplayCell.asObserver(),
                       filterAllTaped: filterAllTaped.asObserver(),
                       filterIncomingTaped: filterIncomingTaped.asObserver(),
                       filterOutgoingTaped: filterOutgoingTaped.asObserver(),
                       modelSelected: modelSelected.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showTransaction: showTransaction.asObservable(),
                         showNoTransactions: sections.map({ (items) -> Bool in
                          return items.reduce(0) { $0 + $1.items.count } == 0 && !self.isLoading
                         }),
                         showAllTransactions: didTapShowAll.asObservable()
    )

    self.dependency = dependency

    sectionTitleDateFormatter.dateFormat = "EEEE, dd MMM"
    sectionTitleDateFullFormatter.dateFormat = "EEEE, dd MMM yyyy"

    bind()
  }

  func bind() {

    filterAllTaped
      .filter({ (_) -> Bool in
        return self.filter != nil
      })
      .throttle(.seconds(1), scheduler: MainScheduler.instance)
      .withLatestFrom(dependency.balanceService.account).map({ (account) -> String? in
      return account?.address
    }).filter { $0 != nil }.map{ $0! }.subscribe(onNext: { [weak self] address in
      self?.filter = nil
      self?.clearResults()
      self?.loadTransactions(address: address, filter: self?.filter, page: 1)
    }).disposed(by: disposeBag)

    filterIncomingTaped
      .filter({ (_) -> Bool in
        return self.filter != .incoming
      })
      .throttle(.seconds(1), scheduler: MainScheduler.instance)
      .withLatestFrom(dependency.balanceService.account).map({ (account) -> String? in
      return account?.address
    }).filter { $0 != nil }.map{ $0! }.subscribe(onNext: { [weak self] address in
      self?.filter = .incoming
      self?.clearResults()
      self?.loadTransactions(address: address, filter: self?.filter, page: 1)
    }).disposed(by: disposeBag)

    filterOutgoingTaped
      .filter({ (_) -> Bool in
        return self.filter != .outgoing
      })
      .throttle(.seconds(1), scheduler: MainScheduler.instance)
      .withLatestFrom(dependency.balanceService.account).map({ (account) -> String? in
      return account?.address
    }).filter { $0 != nil }.map{ $0! }.subscribe(onNext: { [weak self] address in
      self?.filter = .outgoing
      self?.clearResults()
      self?.loadTransactions(address: address, filter: self?.filter, page: 1)
    }).disposed(by: disposeBag)

    let willDisplay = willDisplayCell.filter({ (event) -> Bool in
      let indexPath = event.1
      return self.shouldLoadMore(indexPath)
    }).map { _ in Void() }

    Observable.merge(dependency.balanceService.account.map {_ in Void() }, willDisplay)
      .withLatestFrom(dependency.balanceService.account).map({ (account) -> String? in
        return account?.address
      }).filter { $0 != nil }.map{ $0! }.subscribe(onNext: { [weak self] (address) in
        guard let `self` = self else { return }
        self.createSections(transactions: [])
        self.loadTransactions(address: address, filter: self.filter, page: self.page)
      }).disposed(by: disposeBag)

    didSelectItem.map({ (indexPath) -> IndexPath in
      return IndexPath(row: indexPath.row/2, section: indexPath.section)
    }).map({ (indexPath) -> MinterExplorer.Transaction? in
      return try? self.transactions.value()[safe: indexPath.row]
    }).filter({ (transaction) -> Bool in
      return nil != transaction
    }).subscribe(showTransaction).disposed(by: disposeBag)

    modelSelected.map({ (item) -> MinterExplorer.Transaction? in
      guard let hash = (item as? TransactionCellItem)?.txHash else { return nil }
      return (try? self.transactions.value() ?? [])?.filter({ (tx) -> Bool in
        return tx.hash == hash
      }).first
    }).subscribe(showTransaction).disposed(by: disposeBag)

  }

  // MARK: -

  func createSections(isLoading: Bool? = false, transactions: [MinterExplorer.Transaction]) {
    var newSections = [BaseTableSectionItem]()
    var items = [String: [BaseCellItem]]()

    transactions.forEach { (transaction) in
      guard let txType = transaction.type else { return }

      let existingSections = self.existingSections.filter({ (section) -> Bool in
        return section.header == self.sectionTitle(for: transaction.date)
      })

      let sectionName = existingSections.count > 0 ? "" : sectionTitle(for: transaction.date)
      let sectionIdentifier: String!
      let sectionCandidate = newSections.firstIndex(where: { (item) -> Bool in
        return item.header == sectionName
      })

      var section: BaseTableSectionItem?
      if let idx = sectionCandidate, let sctn = newSections[safe: idx] {
        section = sctn
        sectionIdentifier = sctn.identifier
      } else {
        sectionIdentifier = String.random(length: 20)
        section = BaseTableSectionItem(identifier: sectionIdentifier, header: sectionName)
        section?.items = []
        newSections.append(section!)
      }

      if nil == items[sectionIdentifier] {
        items[sectionIdentifier] = []
      }

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

      let key = transaction.txn != nil ? String(transaction.txn!) : String.random()

      let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(key)")
      items[sectionIdentifier]?.append(cellItem)
      items[sectionIdentifier]?.append(separator)
    }

    let sctns = newSections.map({ (item) -> BaseTableSectionItem in
      return BaseTableSectionItem(identifier: String.random(length: 20), header: item.header, items: (items[item.identifier] ?? []))
    })

    var currentSections = existingSections

    //Moving loading cell to the bottom
    if let loadingIndex = currentSections.firstIndex(where: { (item) -> Bool in
      return item.identifier == "LoadingTableViewSection"
    }) {
      let loadingSection = currentSections[safe: loadingIndex]
      currentSections.remove(at: loadingIndex)
      currentSections = currentSections + sctns
      if nil != loadingSection {
        currentSections.append(loadingSection!)
      }
    } else {
      //Create loading section and cell
      let loadingItem = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell",
                                                 identifier: "LoadingTableViewCell")
      loadingItem.isLoadingObservable = isLoadingObservable.asObservable()
      let section = BaseTableSectionItem(identifier: "LoadingTableViewSection", header: "", items: [loadingItem])

      currentSections = currentSections + sctns + [section]
    }

    sections.onNext(currentSections)
    existingSections = currentSections
  }

  func loadTransactions(address: String, filter: TransactionServiceFilter?, page: Int) {
    guard !stopSearching else { return }

    dependency.transactionService
      .transactions(address: "Mx" + address.stripMinterHexPrefix(), filter: filter, page: page)
      .do(onError: { [weak self] (error) in
        self?.isLoading = false
        self?.isLoadingObservable.onNext(false)
      }, onCompleted: { [weak self] in
        self?.page += 1
        self?.isLoading = false
        self?.isLoadingObservable.onNext(false)
      }, onSubscribe: { [weak self] in
        self?.isLoading = true
        self?.isLoadingObservable.onNext(true)
      })
      .subscribe(onNext: { [weak self] (transactions) in
        guard transactions.count > 0 else {
          self?.stopSearching = true
          return
        }
        var txs = (try? self?.transactions.value()) ?? []
        txs.append(contentsOf: transactions)
        self?.transactions.onNext(txs)
        self?.createSections(transactions: transactions)
      }).disposed(by: disposeBag)
  }

  private func sectionTitle(for date: Date?) -> String {
    guard nil != date else {
      return " "
    }

    if date!.compare(.isToday) {
      return "TODAY".localized()
    } else if date!.compare(.isYesterday) {
      return "YESTERDAY".localized()
    } else if date!.compare(.isThisYear) {
      return sectionTitleDateFormatter.string(from: date!).uppercased()
    } else {
      return sectionTitleDateFullFormatter.string(from: date!).uppercased()
    }
  }

  func shouldLoadMore(_ indexPath: IndexPath) -> Bool {
    guard !isLoading else {
      return false
    }

    let cellItemsLoadedTotal = totalNumberOfItems()
    let fromBottomConstant = 10
    if cellItemsLoadedTotal <= fromBottomConstant {
      return false
    }

    var itemsCountFromPrevSections = 0
    let endSection = indexPath.section - 1
    if endSection >= 0 {
      for index in 0...endSection {
        itemsCountFromPrevSections += existingSections[safe: index]?.items.count ?? 0
      }
    }
    let cellTotalIndex = (indexPath.row + 1) + itemsCountFromPrevSections
    if cellTotalIndex > cellItemsLoadedTotal - fromBottomConstant {
      return true
    }
    return false
  }

  fileprivate func totalNumberOfItems() -> Int {
    return existingSections.reduce(0) { $0 +  $1.items.count }
  }

  func clearResults() {
    self.stopSearching = false
    self.transactions.onNext([])
    self.existingSections = []
    self.page = 1
    self.sections.onNext([])
    self.createSections(transactions: [])
  }

}
