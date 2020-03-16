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

  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var didCancel = PublishSubject<Void>()
  private var didSelect = PublishSubject<Void>()
  private var viewDidLoad = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: SelectWalletViewModel.Input!
  var output: SelectWalletViewModel.Output!
  var dependency: SelectWalletViewModel.Dependency!

  struct Input {
    var didCancel: AnyObserver<Void>
    var didSelect: AnyObserver<Void>
    var viewDidLoad: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var didCancel: Observable<Void>
    var didSelect: Observable<Void>
  }

  struct Dependency {
    var authService: AuthService
  }

  init(dependency: Dependency) {
    self.input = Input(didCancel: didCancel.asObserver(),
                       didSelect: didSelect.asObserver(),
                       viewDidLoad: viewDidLoad.asObserver())
    self.output = Output(sections: sections.asObservable(),
                         didCancel: didCancel.asObservable(),
                         didSelect: didSelect.asObserver())
    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  func bind() {
    viewDidLoad.subscribe(onNext: { [weak self] (_) in
      self?.createSections(accounts: self!.dependency.authService.accounts())
    }).disposed(by: disposeBag)

  }

  func createSections(accounts: [Account]) {
    var section1 = BaseTableSectionItem(identifier: "Wallet",
                                        header: "")
    var items = [BaseCellItem]()
    accounts.forEach { (account) in
      let walletCell = WalletCellItem(reuseIdentifier: "WalletCell",
                                      identifier: "WalletCell_\(account.address)")
      walletCell.title = account.address
      walletCell.emoji = "🐠"
      items.append(walletCell)
    }
    let walletCell = WalletCellItem(reuseIdentifier: "AddWalletCell",
                                    identifier: "AddWalletCell")
    items.append(walletCell)
    section1.items = items
    sections.onNext([section1])
  }

}
