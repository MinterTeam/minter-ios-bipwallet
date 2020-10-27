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

  //Key - PublicKey
  //Value- [CoinSymbol: AddressDelegation]
  var datasource = [String: [String: AddressDelegation]]()
  var validators = [String: ValidatorItem]()

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
    var showKickedWarning: Observable<Bool>
  }

  struct Dependency {
    var balanceService: BalanceService
    var validatorService: ValidatorService
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
  private let showKickedWarning = ReplaySubject<Bool>.create(bufferSize: 1)

  init(dependency: Dependency) {
    super.init()

    self.input = Input(viewDidLoad: viewDidLoad.asObserver(),
                       willDisplayCell: willDisplayCell.asObserver(),
                       didTapUnbond: didTapUnbond.asObserver(),
                       didTapAdd: didTapAdd.asObserver()
    )

    self.output = Output(sections: sections.asObservable(),
                         showDelegate: showDelegate.asObservable(),
                         showUnbond: showUnbond.asObservable(),
                         showKickedWarning: showKickedWarning.asObservable()
    )

    self.dependency = dependency

    bind()

    self.loadData()
  }

  func bind() {
    viewDidLoad.subscribe(onNext: { [weak self] (_) in
//      self?.createSections()
      self?.loadData()
    }).disposed(by: disposeBag)

    didTapAdd.map { _ in nil }.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(showDelegate).disposed(by: disposeBag)
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
      let items = val.value.sorted(by: { (delegation1, delegation2) -> Bool in
        let value1 = delegation1.value.bipValue ?? 0.0
        let value2 = delegation2.value.bipValue ?? 0.0
        return (value1 > value2) && !((delegation1.value.isWaitlisted ?? false) && !(delegation2.value.isWaitlisted ?? false))
      }).map { (delegation) -> [BaseCellItem] in
        let coin = delegation.value.coin?.symbol
        let publicKey = delegation.value.validator?.publicKey
        let value = delegation.value.value
        let bipValue = delegation.value.bipValue
        let isKicked = delegation.value.isWaitlisted ?? false

        let id = "\(publicKey ?? "")_\(coin ?? "")"

        let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                   identifier: "SeparatorTableViewCell_\(id)")

        let coinCell = DelegatedCoinTableViewCellItem(reuseIdentifier: "DelegatedCoinTableViewCell",
                                                      identifier: "DelegatedCoinTableViewCell_\(id)")
        coinCell.title = coin

        coinCell.image = UIImage(named: "AvatarPlaceholderImage")
        if let coin = coin {
          if isKicked {
            coinCell.image = UIImage(named: "WarningIcon")
          } else {
            coinCell.imageURL = MinterMyAPIURL.avatarByCoin(coin: coin).url()
          }
        }

        coinCell.coin = coin
        coinCell.amount = value
        if let coin = coin, coin != Coin.baseCoin().symbol! {
          coinCell.bipAmount = bipValue
        }

        coinCell.didTapMinus.map {
          let validatorsPK = delegation.value.validator?.publicKey ?? ""
          let validator = ValidatorItem(publicKey: validatorsPK, name: delegation.value.validator?.name)
          let validatorsDelegations = self.datasource[validatorsPK]?.mapValues {$0.value ?? 0.0} ?? [:]
          return (validator, delegation.key, validatorsDelegations)
        }.do(onNext: { [weak self] (_) in
          self?.impact.onNext(.light)
          self?.sound.onNext(.click)
        }).subscribe(showUnbond).disposed(by: disposeBag)

        return [coinCell, separator]
      }

      let validatorItem = DelegatedTableViewCellItem(reuseIdentifier: "DelegatedTableViewCell",
                                                     identifier: "DelegatedTableViewCell_\(val.key)")
      validatorItem.publicKey = val.key
      validatorItem.title = val.value.values.first?.validator?.name
      validatorItem.iconURL = val.value.values.first?.validator?.iconURL
      if let publicKey = val.value.values.first?.validator?.publicKey, let validator = self.validators[publicKey] {
        let minStake = coinFormatter.formattedDecimal(with: validator.minStake)
        validatorItem.validatorDesc = "Fee \(validator.commission ?? 100)% | Min. ~\(minStake) \(Coin.baseCoin().symbol!)"
      } else {
        validatorItem.validatorDesc = ""
      }

      validatorItem.didTapAdd.map { _ in return ValidatorItem(publicKey: val.key, name: val.value.values.first?.validator?.name) }
        .subscribe(self.showDelegate)
        .disposed(by: disposeBag)

      validatorItem.didTapCopy
        .map { _ in return ValidatorItem(publicKey: val.key, name: val.value.values.first?.validator?.name) }
        .subscribe(onNext: { [weak self] val in
          UIPasteboard.general.string = val?.publicKey
          self?.showNotifyMessage.onNext("Copied!")
        }).disposed(by: disposeBag)

      let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_\(val.key)")

      let section = BaseTableSectionItem(identifier: "DelegatedSection_\(val.key)",
                                         header: "Stakes".localized(),
                                         items: [validatorItem, separator] + items.flatMap {$0})
      return section
    }
    sections.onNext(sctns)
  }

  func loadData() {
    Observable.combineLatest(dependency.balanceService.delegatedBalance(), dependency.validatorService.validators()).take(1)
      .do(afterNext: { [weak self] (balances, validators) in
        self?.createSections()
      }).subscribe(onNext: { [weak self] (balances, vldtrs) in
        vldtrs.forEach { (validator) in
          self?.validators[validator.publicKey] = validator
        }
        let val = balances
        val.1?.forEach({ (delegation) in
          let key = delegation.validator?.publicKey ?? ""
          if self?.datasource[key] == nil {
            self?.datasource[key] = [:]
          }
          guard let coin = delegation.coin?.symbol else { return }
          self?.datasource[key]?[coin] = delegation
        })

        if val.1?.first(where: { (deleg) -> Bool in
          return deleg.isWaitlisted ?? false
        }) != nil {
          self?.showKickedWarning.onNext(true)
        } else {
          self?.showKickedWarning.onNext(false)
        }
      }).disposed(by: disposeBag)
  }
}
