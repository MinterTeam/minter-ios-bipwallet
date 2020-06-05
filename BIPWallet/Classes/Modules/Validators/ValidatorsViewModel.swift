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
        return self?.validators.filter { (item) -> Bool in
        return item.publicKey == model.identifier
      }.first
    }).filter({ (item) -> Bool in
      return item != nil
    }).do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(didSelect).disposed(by: disposeBag)
  }

  func createSections() {

    let newSections = datasource.sorted(by: { (val1, val2) -> Bool in
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
    sections.onNext(newSections)
  }

  func prepreDatasource(with validators: [ValidatorItem]) {
    datasource = [:]
    validators.sorted(by: { (item1, item2) -> Bool in
      return item1.stake > item2.stake
    }).forEach { (item) in
      var newItem = item
      if newItem.name == nil {
        newItem.name = TransactionTitleHelper.title(from: item.publicKey)
      }

      let key = "All Validators".uppercased().localized()
      let letterArray = datasource[key]
      if letterArray != nil {
        datasource[key]?.append(newItem)
      } else {
        datasource[key] = [newItem]
      }
    }

    createSections()
  }

  func loadData() {
    dependency.validatorService.validators()
      .subscribe(onNext: { [weak self] (items) in
        let valids = items.filter { $0.isOnline }
        self?.validators = valids
        self?.prepreDatasource(with: valids)
      }).disposed(by: disposeBag)
  }

}
