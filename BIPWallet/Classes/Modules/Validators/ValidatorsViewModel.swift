//
//  ValidatorsViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift

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

  private var validators = [ValidatorItem]()
  private var datasource = [String: [ValidatorItem]]()
  private var didSelect = PublishSubject<ValidatorItem?>()
  private var sections = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
  private var viewWillAppear = PublishSubject<Void>()
  private var modelSelected = PublishSubject<BaseCellItem>()

  func bind() {

    modelSelected
      .map({ [weak self] (model) -> ValidatorItem? in
        if let item = self?.validators.filter { (item) -> Bool in
        return item.publicKey == model.identifier
        }.first {
          return item
        } else if let lastUsed = self?.dependency.validatorService.lastUsedPublicKey {
          let item = self?.validators.filter {$0.publicKey == lastUsed }.first ?? ValidatorItem(publicKey: lastUsed)
          if model.identifier.starts(with: "LastUsed_") {
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
    }).map { (val) -> BaseTableSectionItem in
      let items = val.value.map { (item) -> ContactEntryTableViewCellItem in
        let contactItem = ContactEntryTableViewCellItem(reuseIdentifier: "ContactEntryTableViewCell",
                                                        identifier: item.publicKey)
        contactItem.address = item.publicKey
        contactItem.name = item.name
        contactItem.avatarURL = item.iconURL
        return contactItem
      }
      return BaseTableSectionItem(identifier: "BaseTableSectionItem_\(val.key)", header: val.key, items: items)
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
    guard let lastUsed = self.dependency.validatorService.lastUsedPublicKey else {
      return nil
    }
    var items: [BaseCellItem] = []
    let validator = self.validators.filter { (item) -> Bool in
      return item.publicKey == lastUsed
    }.first ?? ValidatorItem(publicKey: lastUsed, name: TransactionTitleHelper.title(from: lastUsed))

    let item = ContactEntryTableViewCellItem(reuseIdentifier: "ContactEntryTableViewCell", identifier: "LastUsed_\(String.random())")
    item.address = validator?.publicKey
    item.name = validator?.name ?? TransactionTitleHelper.title(from: lastUsed)
    item.avatarURL = validator?.iconURL
    // self.contactItem(with: contact, identifier: lastUsedCellIdentifier(item: contact))
    items = [item]
    return BaseTableSectionItem(identifier: "LastUsed", header: "LAST USED", items: items)
  }

  func loadData() {
    dependency.validatorService.validators()
      .subscribe(onNext: { [weak self] (items) in
        let valids = items.filter { $0.isOnline }
        self?.validators = valids
        self?.prepreDatasource(with: valids)
        self?.createSections()
      }).disposed(by: disposeBag)
  }

}
