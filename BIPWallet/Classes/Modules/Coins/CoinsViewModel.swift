//
//  CoinsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy

class CoinsViewModel: BaseViewModel, ViewModel {

  typealias BalanceModel = [String: (Decimal, Decimal)]

  // MARK: -

  private var coins = BehaviorSubject<BalanceModel>(value: [:])
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewDidLoad = PublishSubject<Void>()

  private var isLoading = false

  // MARK: - ViewModel

  var input: CoinsViewModel.Input!
  var output: CoinsViewModel.Output!
  var dependency: CoinsViewModel.Dependency!

  struct Input {
    var coins: AnyObserver<BalanceModel>
    var viewDidLoad: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  init(dependency: Dependency) {
    self.input = Input(coins: coins.asObserver(),
                       viewDidLoad: viewDidLoad.asObserver())
    self.output = Output(sections: sections.asObservable())
    self.dependency = dependency

    super.init()

    bind()
  }

  func bind() {
    dependency.balanceService
      .balances()
      .do(onNext: { (txs) in
        
      }, onError: { [weak self] (error) in
        self?.isLoading = false
        let coins = (try? self?.coins.value()) ?? [:]
        self?.createSections(isLoading: self?.isLoading, coins: coins)
      }, onCompleted: { [weak self] in
        self?.isLoading = false
        let coins = (try? self?.coins.value()) ?? [:]
        self?.createSections(isLoading: self?.isLoading, coins: coins)
      }, onSubscribe: { [weak self] in
        self?.isLoading = true
        let coins = (try? self?.coins.value()) ?? [:]
        self?.createSections(isLoading: self?.isLoading, coins: coins)
      })
      .subscribe(onNext: { [weak self] (coins) in
        self?.isLoading = false
        self?.coins.onNext(coins.balances)
      }).disposed(by: disposeBag)

    Observable.combineLatest(viewDidLoad, coins).map({ (val) -> BalanceModel in
      return val.1
    }).subscribe(onNext: { [weak self] (coins) in
      self?.createSections(isLoading: self?.isLoading ?? false, coins: coins)
    }).disposed(by: disposeBag)

  }

  // MARK: -

  func createSections(isLoading: Bool? = false, coins: BalanceModel) {
    var section1 = BaseTableSectionItem(identifier: "CoinSection1",
                                        header: "")

    let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
                                                identifier: "ButtonTableViewCell_Convert")
    convertButton.buttonPattern = "blank"
    convertButton.title = "Exchange".localized()

    section1.items.append(convertButton)

    var cellItems = [BaseCellItem]()
    var section2 = BaseTableSectionItem(identifier: "CoinSection2",
                                        header: "MY COINS".localized())

    if isLoading ?? false {
      let loadingCell = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell",
                                                 identifier: "LoadingTableViewCell")
      cellItems.append(loadingCell)
    }

    coins.keys.sorted(by: { (key1, key2) -> Bool in
      return (key1 == Coin.baseCoin().symbol!) ? true
        : (key2 == Coin.baseCoin().symbol!) ? false
        : (key1 < key2)
    }).forEach { (key) in
      let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(key)")
      let coin = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell",
                                       identifier: "CoinTableViewCell_\(key)_\(String(describing: coins[key]))")
      coin.title = key
      coin.image = UIImage(named: "AvatarPlaceholderImage")
      coin.imageURL = MinterMyAPIURL.avatarByCoin(coin: key).url()
      coin.coin = key
      coin.amount = coins[key]?.0
      coin.bipAmount = coins[key]?.1
      cellItems.append(coin)
      cellItems.append(separator)
    }

    var newSections = [section1]
    if cellItems.count > 0 {
      section2.items = cellItems
      newSections.append(section2)
    }

    sections.onNext(newSections)
  }

}
