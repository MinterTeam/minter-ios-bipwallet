//
//  SelectWalletViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy

class SelectWalletViewModel: BaseViewModel, ViewModel {

  // MARK: -

  lazy var accounts = self.dependency.authService.accounts()

  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var didCancel = PublishSubject<Void>()
  private var didSelectItem = PublishSubject<IndexPath>()
  private var didSelect = PublishSubject<String>()
  private var showEdit = PublishSubject<String>()
  private var viewDidLoad = PublishSubject<Void>()
  private var showAdd = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SelectWalletViewModel.Input!
  var output: SelectWalletViewModel.Output!
  var dependency: SelectWalletViewModel.Dependency!

  struct Input {
    var didCancel: AnyObserver<Void>
    var didSelect: AnyObserver<IndexPath>
    var viewDidLoad: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var didCancel: Observable<Void>
    var didSelect: Observable<String>
    var showEdit: Observable<String>
    var showAdd: Observable<Void>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(didCancel: didCancel.asObserver(),
                       didSelect: didSelectItem.asObserver(),
                       viewDidLoad: viewDidLoad.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         didCancel: didCancel.asObservable(),
                         didSelect: didSelectObserable(),
                         showEdit: showEdit.asObservable(),
                         showAdd: showAddObservable()
    )

    bind()
  }

  // MARK: -

  func didSelectObserable() -> Observable<String> {
    return didSelectItem.filter({ (indexPath) -> Bool in
      return self.accounts[safe: indexPath.row] != nil
    }).map { (indexPath) -> String in
      return self.accounts[indexPath.row].address
    }
  }

  func showAddObservable() -> Observable<Void> {
    return didSelectItem.filter({ (indexPath) -> Bool in
      return self.accounts[safe: indexPath.row] == nil
    }).map { (_) -> Void in
      return Void()
    }
  }

  func bind() {
    viewDidLoad.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      self.createSections(accounts: self.accounts)
    }).disposed(by: disposeBag)
  }

  func createSections(accounts: [AccountItem]) {
    var section1 = BaseTableSectionItem(identifier: "Wallet",
                                        header: "")

    var items = [BaseCellItem]()
    accounts.forEach { (account) in
      let walletCell = WalletCellItem(reuseIdentifier: "WalletCell",
                                      identifier: "WalletCell_\(account.address)")
      walletCell.title = TransactionTitleHelper.title(from: account.address)
      walletCell.emoji = account.emoji
      items.append(walletCell)
    }

    let walletCell = WalletCellItem(reuseIdentifier: "AddWalletCell",
                                    identifier: "AddWalletCell")
    items.append(walletCell)
    section1.items = items
    sections.onNext([section1])
  }

}
