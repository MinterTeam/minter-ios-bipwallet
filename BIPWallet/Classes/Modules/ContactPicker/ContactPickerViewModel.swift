//
//  ContactPickerViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 28/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy

enum ContactPickerViewModelError: Error {
  case cantFindContactItem
}

class ContactPickerViewModel: BaseViewModel, ViewModel {

  // MARK: - ViewModel

  var input: ContactPickerViewModel.Input!
  var output: ContactPickerViewModel.Output!
  var dependency: ContactPickerViewModel.Dependency!

  struct Input {
    var didTapAddContact: AnyObserver<Void>
    var viewWillAppear: AnyObserver<Void>
    var didSelectItem: AnyObserver<IndexPath>
    var modelSelected: AnyObserver<BaseCellItem>
    var didAddContact: AnyObserver<ContactItem?>
    var editItem: AnyObserver<IndexPath?>
    var deleteItem: AnyObserver<IndexPath?>
  }

  struct Output {
    var didSelectContact: Observable<ContactItem?>
    var sections: Observable<[BaseTableSectionItem]>
    var showAddContact: Observable<Void>
    var scrollToCell: Observable<IndexPath?>
    var showError: Observable<String?>
    var editContact: Observable<ContactItem>
  }

  struct Dependency {
    var contactsService: ContactsService
  }

  init(dependency: Dependency) {

    self.input = Input(didTapAddContact: didTapAddContact.asObserver(),
                       viewWillAppear: viewWillAppear.asObserver(),
                       didSelectItem: itemSelected.asObserver(),
                       modelSelected: modelSelected.asObserver(),
                       didAddContact: didAddContact.asObserver(),
                       editItem: editItem.asObserver(),
                       deleteItem: deleteItem.asObserver()
    )

    self.output = Output(didSelectContact: didSelectContact.asObservable(),
                         sections: sections.asObservable(),
                         showAddContact: didTapAddContact.asObservable(),
                         scrollToCell: scrollToCell.asObservable(),
                         showError: showError.asObservable(),
                         editContact: editContact.asObservable()
    )

    self.dependency = dependency

    super.init()

    bind()
  }

  // MARK: -

  private var contacts = [ContactItem]()
  private var datasource = [String: [ContactItem]]()
  private var didSelectContact = PublishSubject<ContactItem?>()
  private var didTapAddContact = PublishSubject<Void>()
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewWillAppear = PublishSubject<Void>()
  private var itemSelected = PublishSubject<IndexPath>()
  private var modelSelected = PublishSubject<BaseCellItem>()
  private var didAddContact = PublishSubject<ContactItem?>()
  private var scrollToCell = PublishSubject<IndexPath?>()
  private var editItem = PublishSubject<IndexPath?>()
  private var deleteItem = PublishSubject<IndexPath?>()
  private var showError = PublishSubject<String?>()
  private var editContact = PublishSubject<ContactItem>()

  func bind() {

    Observable.merge(viewWillAppear.asObservable(), didAddContact.asObservable().map { _ in Void() })
      .throttle(.seconds(1), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] (_) in
        self?.loadData()
    }).disposed(by: disposeBag)

    modelSelected.map({ [weak self] (model) -> ContactItem? in
      return self?.contacts.filter { (item) -> Bool in
        return (self?.cellIdentifierFor(item: item) ?? "") == model.identifier
      }.first
    }).filter({ (item) -> Bool in
      return item != nil
    }).do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(didSelectContact).disposed(by: disposeBag)

    deleteItem.withLatestFrom(Observable.combineLatest(sections, deleteItem))
      .map({ [weak self] (val) -> ContactItem? in
      let sections = val.0
      let cellIndexPath = val.1

      guard let indexPath = cellIndexPath, let model = sections[safe: indexPath.section]?.items[safe: indexPath.row] else { return nil }

      return self?.contacts.filter { (item) -> Bool in
        return (self?.cellIdentifierFor(item: item) ?? "") == model.identifier
      }.first
    }).filter({ (item) -> Bool in
      return item != nil
    }).flatMap({ (item) -> Observable<Event<Void>> in
      guard let item = item else { return Observable.error(ContactPickerViewModelError.cantFindContactItem) }
      return self.dependency.contactsService.delete(item).materialize()
    }).do(onNext: { [weak self] (_) in
      self?.impact.onNext(.hard)
      self?.sound.onNext(.click)
    }).subscribe(onNext: { [weak self] (res) in
      switch res {
      case .error(_):
        break

      default:
        self?.loadData()
      }
    }).disposed(by: disposeBag)

    editItem.withLatestFrom(Observable.combineLatest(sections, editItem))
      .map({ [weak self] (val) -> ContactItem? in
      let sections = val.0
      let cellIndexPath = val.1

      guard let indexPath = cellIndexPath, let model = sections[safe: indexPath.section]?.items[safe: indexPath.row] else { return nil }

      return self?.contacts.filter { (item) -> Bool in
        return (self?.cellIdentifierFor(item: item) ?? "") == model.identifier
      }.first
    }).filter({ (item) -> Bool in
      return item != nil
    }).map { $0! }.do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(editContact).disposed(by: disposeBag)

    Observable.zip(sections, didAddContact).map({ [weak self] (val) -> IndexPath? in
      let sections = val.0
      guard let `self` = self, let contact = val.1 else { return nil }

      var section: Int?
      var row: Int?
      for i in 0..<sections.count {
       row = sections[safe: i]?.items.firstIndex(where: { (item) -> Bool in
         return item.identifier == self.cellIdentifierFor(item: contact)
       })
       if row != nil {
         section = i
         break
        }
      }
      if let section = section, let row = row {
       return IndexPath(row: row, section: section)
      }
      return nil
    }).delay(.milliseconds(10), scheduler: MainScheduler.instance)
    .subscribe(scrollToCell).disposed(by: disposeBag)
  }

  func createSections() {

    let newSections = datasource.sorted(by: { (val1, val2) -> Bool in
      return val1.key < val2.key
    }).map { (val) -> BaseTableSectionItem in
      let items = val.value.sorted().map { (item) -> ContactEntryTableViewCellItem in
        let contactItem = ContactEntryTableViewCellItem(reuseIdentifier: "ContactEntryTableViewCell",
                                                        identifier: self.cellIdentifierFor(item: item))
        contactItem.address = item.address
        contactItem.name = item.name?.capitalized
        if let address = item.address {
          contactItem.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
        }
        return contactItem
      }
      return BaseTableSectionItem(identifier: "BaseTableSectionItem_\(val.key)", header: val.key, items: items)
    }
    sections.onNext(newSections)
  }

  func prepreDatasource(with contacts: [ContactItem]) {
    datasource = [:]
    contacts.forEach { (item) in
      guard let name = item.name, !name.isEmpty else { return }
      let firstLitter = name.prefix(1)
      let key = String(firstLitter).capitalized
      let letterArray = datasource[key]
      if letterArray != nil {
        datasource[key]?.append(item)
      } else {
        datasource[key] = [item]
      }
    }
    createSections()
  }

  func loadData() {
    self.dependency
      .contactsService
      .contacts()
      .subscribe(onNext: { [weak self] (items) in
        self?.contacts = items
        self?.prepreDatasource(with: items)
    }).disposed(by: disposeBag)
  }

  private func cellIdentifierFor(item: ContactItem) -> String {
    return "ContactEntryTableViewCell_\(item.address ?? String.random())"
  }

}
