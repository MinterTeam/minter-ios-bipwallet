//
//  ValidatorsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore

class ValidatorsViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: ValidatorsViewModel.Input!
  var output: ValidatorsViewModel.Output!
  var dependency: ValidatorsViewModel.Dependency!

  struct Input {
    var modelSelected: AnyObserver<BaseCellItem>
  }

  struct Output {
    var didSelect: Observable<ValidatorItem?>
    var sections: Observable<[BaseTableSectionItem]>
  }

  struct Dependency {
    var validatorService: ValidatorService
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(
      modelSelected: modelSelected.asObserver()
    )

    self.output = Output(
      didSelect: didSelect.asObservable(),
      sections: sections.asObservable()
    )

    bind()

    dependency.validatorService.updateValidators()

    loadData()
  }

  // MARK: -

  private let lastUsedIdentifierPrefix = "LastUsed_"
  private var allValidators = [ValidatorItem]()
  private var validators = [ValidatorItem]()
  private var datasource = [String: [ValidatorItem]]()
  private var didSelect = PublishSubject<ValidatorItem?>()
  private var sections = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
  private var viewWillAppear = PublishSubject<Void>()
  private var modelSelected = PublishSubject<BaseCellItem>()

  func bind() {

    modelSelected.map({ [unowned self] (model) -> ValidatorItem? in
      if let item = self.validators.filter { (item) -> Bool in
        return item.publicKey == model.identifier
      }.first {
        return item
      } else if let lastUsed = self.dependency.validatorService.lastUsedPublicKey {
        let item = self.validators.filter { $0.publicKey == lastUsed }.first ?? ValidatorItem(publicKey: lastUsed)
        if model.identifier.starts(with: self.lastUsedIdentifierPrefix) {
         return item
        }
      }
      return nil
    }).filter({ (item) -> Bool in
      return item != nil
    }).do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(didSelect).disposed(by: disposeBag)
  }

  func createSections() {

    var newSections = datasource.sorted(by: { (val1, val2) -> Bool in
      return val1.key < val2.key
    }).map { [unowned self] (val) -> BaseTableSectionItem in
      let items = val.value.map { (item) -> ValidatorTableViewCellItem in
        return self.validatorCellItem(validator: item)
      }
      return BaseTableSectionItem(identifier: "BaseTableSection_\(val.key)", header: val.key, rightHeader: "FEE".localized(), items: items)
    }
    if let lastUsedSection = self.lastUsedSection() {
      newSections.insert(lastUsedSection, at: 0)
    }
    sections.onNext(newSections)
  }

  func prepreDatasource(with validators: [ValidatorItem]) {
    datasource = [:]
    validators.sorted(by: { (item1, item2) -> Bool in
      return item1.stake > item2.stake
    }).forEach { (item) in
      var newItem = item
      newItem.name = newItem.name ?? TransactionTitleHelper.title(from: item.publicKey)

      let key = "All Validators".uppercased().localized()
      let letterArray = datasource[key]
      if letterArray != nil {
        datasource[key]?.append(newItem)
      } else {
        datasource[key] = [newItem]
      }
    }
  }

  func lastUsedSection() -> BaseTableSectionItem? {
    guard
      let lastUsed = self.dependency.validatorService.lastUsedPublicKey,
      var validator = self.allValidators.filter({ (item) -> Bool in
        return item.publicKey == lastUsed
      }).first ?? ValidatorItem(publicKey: lastUsed, name: TransactionTitleHelper.title(from: lastUsed)) else {
      return nil
    }
    validator.name = validator.name ?? TransactionTitleHelper.title(from: lastUsed)
    var items: [BaseCellItem] = []
    items = [self.validatorCellItem(validator: validator, identifierPrefix: lastUsedIdentifierPrefix)]

    return BaseTableSectionItem(identifier: "LastUsed", header: "LAST USED", items: items)
  }

  func loadData() {
    dependency.validatorService.validators()
      .subscribe(onNext: { [weak self] (items) in
        self?.allValidators = items
        let valids = items.filter { $0.isOnline }
        self?.validators = valids
        self?.prepreDatasource(with: valids)
        self?.createSections()
      }).disposed(by: disposeBag)
  }

  // MARK: -

  func validatorCellItem(validator item: ValidatorItem, identifierPrefix: String = "") -> ValidatorTableViewCellItem {
    let contactItem = ValidatorTableViewCellItem(reuseIdentifier: "ValidatorTableViewCell",
                                                 identifier: identifierPrefix + item.publicKey)
    contactItem.publicKey = TransactionTitleHelper.title(from: item.publicKey)
    contactItem.name = item.name
    contactItem.avatarURL = item.iconURL
    contactItem.commission = "\(item.commission ?? 100) %"
    var minStake = item.minStake
    minStake.round(.toNearestOrEven)
    contactItem.minStake = "Min. ~\(minStake) \(Coin.baseCoin().symbol!)"
    return contactItem
  }

}
