//
//  DelegatedViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 10/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MinterCore
import MinterExplorer
import MinterMy

class DelegatedViewModel: BaseViewModel, ViewModel {

  // MARK: -

  var datasource = [String: [String: AddressDelegation]]()

  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  // MARK: - ViewModel

  var input: DelegatedViewModel.Input!
  var output: DelegatedViewModel.Output!
  var dependency: DelegatedViewModel.Dependency!

  struct Input {
    var viewDidLoad: AnyObserver<Void>
    var willDisplayCell: AnyObserver<WillDisplayCellEvent>
    var didTapUnbond: AnyObserver<IndexPath?>
    var didTapAdd: AnyObserver<Void>
  }

  struct Output {
    var sections: Observable<[BaseTableSectionItem]>
    var showDelegate: Observable<ValidatorItem?>
    var showUnbond: Observable<(ValidatorItem?, String?, [String: Decimal]?)>
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  // MARK: -

  //start with second page because we already have first page results
  private var page = 1
  private var isLoading = false
  private var canLoadMore = true
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewDidLoad = PublishSubject<Void>()
  private var willDisplayCell = PublishSubject<WillDisplayCellEvent>()
  private var didTapUnbond = PublishSubject<IndexPath?>()
  private let showDelegate = PublishSubject<ValidatorItem?>()
  private let showUnbond = PublishSubject<(ValidatorItem?, String?, [String: Decimal]?)>()
  private let didTapAdd = PublishSubject<Void>()

  init(dependency: Dependency) {
    super.init()

    self.input = Input(viewDidLoad: viewDidLoad.asObserver(),
                       willDisplayCell: willDisplayCell.asObserver(),
                       didTapUnbond: didTapUnbond.asObserver(),
                       didTapAdd: didTapAdd.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showDelegate: showDelegate.asObservable(),
                         showUnbond: showUnbond.asObservable()
    )

    self.dependency = dependency

    bind()

    self.loadData()
  }

  func bind() {
    viewDidLoad.subscribe(onNext: { [weak self] (_) in
      self?.createSections()
      self?.loadData()
    }).disposed(by: disposeBag)

    didTapAdd.map { _ in nil }.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(showDelegate).disposed(by: disposeBag)

    //TODO: look if can migrate to 'model selected'
    didTapUnbond.map { (indexPath) -> (ValidatorItem?, String?, [String: Decimal]?) in
      guard let indexPath = indexPath else { return (nil, nil, nil) }

      let section = indexPath.section
      let row = indexPath.row/2 - 1

      let coin = self.sectionData()[safe: section]?.value.sorted(by: { (delegation1, delegation2) -> Bool in
        let key1 = delegation1.value.coin ?? ""
        let key2 = delegation2.value.coin ?? ""
        return (key1 == Coin.baseCoin().symbol!) ? true
          : (key2 == Coin.baseCoin().symbol!) ? false
          : (key1 < key2)
      })[safe: row]

      if let item = coin?.value, let publicKey = item.publicKey, let amount = self.datasource[publicKey] {
        return (ValidatorItem(publicKey: publicKey, name: item.validatorName), coin?.key, amount.mapValues({ (delegation) -> Decimal in
          return delegation.value ?? 0.0
        }))
      }
      return (nil, nil, nil)
    }.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(showUnbond).disposed(by: disposeBag)
  }

  //Sorting keys according to overall bipValue delegated
  func sectionData() -> [Dictionary<String, [String: AddressDelegation]>.Element] {
    let sortedDatasource = self.datasource.sorted(by: { (val1, val2) -> Bool in
      let bipSum1 = val1.value.values.reduce(Decimal(0.0)) { $0 + ($1.bipValue ?? 0.0) }
      let bipSum2 = val2.value.values.reduce(Decimal(0.0)) { $0 + ($1.bipValue ?? 0.0) }
      return bipSum1 > bipSum2
    })
    return sortedDatasource
  }

  func createSections() {

    let sctns = sectionData().map { (val) -> BaseTableSectionItem in
      //Sortin coins: First - base coin
      let items = val.value.sorted(by: { (delegation1, delegation2) -> Bool in
        let key1 = delegation1.value.coin ?? ""
        let key2 = delegation2.value.coin ?? ""

        let value1 = delegation1.value.bipValue ?? 0.0
        let value2 = delegation2.value.bipValue ?? 0.0

        return (key1 == Coin.baseCoin().symbol!) ? true
          : (key2 == Coin.baseCoin().symbol!) ? false
          : (value1 > value2)
      }).map { (delegation) -> [BaseCellItem] in
        let coin = delegation.value.coin
        let publicKey = delegation.value.publicKey
        let value = delegation.value.value
        let bipValue = delegation.value.bipValue

        let id = "\(publicKey ?? "")_\(coin ?? "")"

        let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                   identifier: "SeparatorTableViewCell_\(id)")

        let coinCell = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell",
                                             identifier: "CoinTableViewCell_\(id)")
        coinCell.title = coin
        coinCell.image = UIImage(named: "AvatarPlaceholderImage")
        if let coin = coin {
          coinCell.imageURL = MinterMyAPIURL.avatarByCoin(coin: coin).url()
        }
        coinCell.coin = coin
        coinCell.amount = value
        if let coin = coin, coin != Coin.baseCoin().symbol! {
          coinCell.bipAmount = bipValue
        }

        return [coinCell, separator]
      }

      let validatorItem = DelegatedTableViewCellItem(reuseIdentifier: "DelegatedTableViewCell",
                                                     identifier: "DelegatedTableViewCell_\(val.key)")
      validatorItem.publicKey = val.key
      validatorItem.iconURL = val.value.values.first?.validatorIconURL

      validatorItem.didTapAdd.map { _ in return ValidatorItem(publicKey: val.key, name: val.value.values.first?.validatorName) }
        .subscribe(self.showDelegate)
        .disposed(by: disposeBag)

      validatorItem.didTapCopy
        .map { _ in return ValidatorItem(publicKey: val.key, name: val.value.values.first?.validatorName) }
        .subscribe(onNext: { [weak self] val in
          UIPasteboard.general.string = val.publicKey
          self?.showNotifyMessage.onNext("Copied!")
        })
        .disposed(by: disposeBag)

      let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(val.key)")

      let section = BaseTableSectionItem(identifier: String.random(),
                                         header: "Stakes".localized(),
                                         items: [validatorItem, separator] + items.flatMap {$0})
      return section
    }
    sections.onNext(sctns)
  }

  func loadData() {
    self.dependency.balanceService.delegatedBalance()
      .do(afterNext: { [weak self] (val) in
        self?.createSections()
      }).subscribe(onNext: { [weak self] (val) in
        val.0?.forEach({ (delegation) in
          let key = delegation.publicKey ?? ""
          if self?.datasource[key] == nil {
            self?.datasource[key] = [:]
          }

          guard let coin = delegation.coin else { return }

          self?.datasource[key]?[coin] = delegation
        })
      }).disposed(by: disposeBag)
  }
}
