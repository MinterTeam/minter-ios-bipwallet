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
  private let lastUsedHeaderTitle = "LAST USED".localized()
  private var didSelect = PublishSubject<ValidatorItem?>()
  private var sections = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
  private var viewWillAppear = PublishSubject<Void>()
  private var modelSelected = PublishSubject<BaseCellItem>()

  func bind() {

    modelSelected.withLatestFrom(dependency.validatorService.validators()) { ($0, $1) }.map({ [unowned self] (model, validators) -> ValidatorItem? in
      if let item = validators.first(where: { (itm) -> Bool in
        return itm.publicKey == model.identifier
      }) {
        return item
      } else if let lastUsed = self.dependency.validatorService.lastUsedPublicKey {
        let item = validators.filter { $0.publicKey == lastUsed }.first ?? ValidatorItem(publicKey: lastUsed)
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

  func createSections(data: [String: [ValidatorItem]]) -> [BaseTableSectionItem] {
    return data.sorted(by: { (val1, val2) -> Bool in
      if val1.key == self.lastUsedHeaderTitle { return true } else if val2.key == self.lastUsedHeaderTitle { return false }
      return val1.key < val2.key
    }).map { [unowned self] (val) -> BaseTableSectionItem in
      let items = val.value.map { (item) -> ValidatorTableViewCellItem in
        return self.validatorCellItem(validator: item,
                                      identifierPrefix: val.key == self.lastUsedHeaderTitle ? self.lastUsedIdentifierPrefix : "")
      }
      return BaseTableSectionItem(identifier: "BaseTableSection_\(val.key)",
        header: val.key,
        rightHeader: "FEE".localized(),
        items: items)
    }
  }

  func prepreDatasource(with validators: [ValidatorItem]) -> [String: [ValidatorItem]] {
    var data: [String: [ValidatorItem]] = [:]
    validators.filter { $0.isOnline }.sorted(by: { (item1, item2) -> Bool in
      return item1.stake > item2.stake
    }).forEach { (item) in
      var newItem = item
      newItem.name = newItem.name ?? TransactionTitleHelper.title(from: item.publicKey)

      let key = "All Validators".uppercased().localized()
      let letterArray = data[key]
      if letterArray != nil {
        data[key]?.append(newItem)
      } else {
        data[key] = [newItem]
      }
    }

    if
      let lastUsed = self.dependency.validatorService.lastUsedPublicKey,
      var validator = validators.first(where: { (item) -> Bool in
        return item.publicKey == lastUsed
      }) ?? ValidatorItem(publicKey: lastUsed,
                          name: TransactionTitleHelper.title(from: lastUsed)) {
      validator.name = validator.name ?? TransactionTitleHelper.title(from: lastUsed)
      data[lastUsedHeaderTitle] = [validator]
    }
    return data
  }

  func loadData() {
    dependency.validatorService.validators()
      .map { return self.prepreDatasource(with: $0) }
      .map { self.createSections(data: $0) }
      .subscribe(sections)
      .disposed(by: disposeBag)
  }

  // MARK: -

  func validatorCellItem(validator item: ValidatorItem, identifierPrefix: String = "") -> ValidatorTableViewCellItem {
    let contactItem = ValidatorTableViewCellItem(reuseIdentifier: "ValidatorTableViewCell",
                                                 identifier: identifierPrefix + item.publicKey)
    contactItem.publicKey = TransactionTitleHelper.title(from: item.publicKey)
    contactItem.name = item.name
    contactItem.avatarURL = item.iconURL
    contactItem.commission = "\(item.commission ?? 100) %"
    let minStake = CurrencyNumberFormatter.coinFormatter.formattedDecimal(with: item.minStake)
    contactItem.minStake = "Min. ~\(minStake) \(Coin.baseCoin().symbol!)"
    return contactItem
  }

}
