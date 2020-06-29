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
    var modelSelected: AnyObserver<BaseCellItem>
    var didAddContact: AnyObserver<ContactItem?>
    var editItem: AnyObserver<IndexPath?>
    var deleteItem: AnyObserver<IndexPath?>
    var deleteContact: AnyObserver<ContactItem>
  }

  struct Output {
    var didSelectContact: Observable<ContactItem?>
    var sections: Observable<[BaseTableSectionItem]>
    var showAddContact: Observable<Void>
    var scrollToCell: Observable<IndexPath?>
    var showError: Observable<String?>
    var editContact: Observable<ContactItem>
    var deleteContact: Observable<ContactItem>
    var hasLastUsed: Bool
  }

  struct Dependency {
    var contactsService: ContactsService
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(didTapAddContact: didTapAddContact.asObserver(),
                       viewWillAppear: viewWillAppear.asObserver(),
                       modelSelected: modelSelected.asObserver(),
                       didAddContact: didAddContact.asObserver(),
                       editItem: editItem.asObserver(),
                       deleteItem: deleteItem.asObserver(),
                       deleteContact: deleteContact.asObserver()
    )

    self.output = Output(didSelectContact: didSelectContact.asObservable(),
                         sections: sections.asObservable(),
                         showAddContact: didTapAddContact.asObservable(),
                         scrollToCell: scrollToCell.asObservable(),
                         showError: showError.asObservable(),
                         editContact: editContact.asObservable(),
                         deleteContact: deleteItem.withLatestFrom(Observable.combineLatest(sections, deleteItem))
                           .map({ [weak self] (val) -> ContactItem? in
                             let sections = val.0
                             let cellIndexPath = val.1

                             guard let indexPath = cellIndexPath, let model = sections[safe: indexPath.section]?.items[safe: indexPath.row] else { return nil }

                             return self?.contacts.filter { (item) -> Bool in
                               return (self?.cellIdentifierFor(item: item) ?? "") == model.identifier
                             }.first
                           }).filter{ $0 != nil }.map { $0! },
                         hasLastUsed: (self.dependency.contactsService.lastUsedAddress ?? "").isValidAddress()
    )

    bind()
  }

  // MARK: -

  private var contacts = [ContactItem]()
  private var datasource = [String: [ContactItem]]()
  private var didSelectContact = PublishSubject<ContactItem?>()
  private var didTapAddContact = PublishSubject<Void>()
  private var sections = PublishSubject<[BaseTableSectionItem]>()
  private var viewWillAppear = PublishSubject<Void>()
  private var modelSelected = PublishSubject<BaseCellItem>()
  private var didAddContact = PublishSubject<ContactItem?>()
  private var scrollToCell = PublishSubject<IndexPath?>()
  private var editItem = PublishSubject<IndexPath?>()
  private var deleteItem = PublishSubject<IndexPath?>()
  private var showError = PublishSubject<String?>()
  private var editContact = PublishSubject<ContactItem>()
  private var deleteContact = PublishSubject<ContactItem>()

  func bind() {

    Observable.merge(viewWillAppear.asObservable(), didAddContact.asObservable().map { _ in Void() })
      .throttle(.seconds(1), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] (_) in
        self?.loadData()
    }).disposed(by: disposeBag)

    modelSelected.map({ [weak self] (model) -> ContactItem? in
      if let item = self?.contacts.filter { (item) -> Bool in
        return (self?.cellIdentifierFor(item: item) ?? "") == model.identifier
      }.first {
        return item
      } else if let lastUsed = self?.dependency.contactsService.lastUsedAddress {
        let item = self?.contacts.filter {$0.address == lastUsed }.first ?? ContactItem(name: nil, address: lastUsed)
        if model.identifier.starts(with: "LastUsed_")  {
          return item
        }
      }
      return nil
    }).filter({ (item) -> Bool in
      return item != nil
    }).do(onNext: { [weak self] (_) in
      self?.impact.onNext(.light)
      self?.sound.onNext(.click)
    }).subscribe(didSelectContact).disposed(by: disposeBag)

    deleteContact.flatMap({ (item) -> Observable<Event<Void>> in
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

    Observable.zip(sections.skip(1), didAddContact)
      .delay(.milliseconds(10), scheduler: MainScheduler.instance)
      .map({ [weak self] (val) -> IndexPath? in
        let sections = val.0
        guard let `self` = self, let contact = val.1 else { return nil }

        var section: Int?
        var row: Int?
        for i in 0..<sections.count {
          row = sections[safe: i]?.items.firstIndex(where: { (item) -> Bool in
            return (item.identifier.components(separatedBy: "|").first ?? "")
              == self.cellIdentifierFor(item: contact).components(separatedBy: "|").first ?? ""
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
      }).subscribe(scrollToCell).disposed(by: disposeBag)
  }

  func createSections() {

    var newSections = datasource.sorted(by: { (val1, val2) -> Bool in
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

    if let lastUsedSecton = self.lastUsedSecton() {
      newSections.insert(lastUsedSecton, at: 0)
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
  }

  func loadData() {
    dependency.contactsService.contacts()
      .subscribe(onNext: { [weak self] (items) in
        self?.contacts = items
        self?.prepreDatasource(with: items)
        self?.createSections()
      }).disposed(by: disposeBag)
  }

  private func cellIdentifierFor(item: ContactItem) -> String {
    //we need a unique identifier so cell can be reloaded
    return "ContactEntryTableViewCell_\(item.address ?? String.random())" + "|" + (item.name ?? String.random())
  }

  func lastUsedSecton() -> BaseTableSectionItem? {
    guard let lastUsed = self.dependency.contactsService.lastUsedAddress else {
      return nil
    }
    var items: [BaseCellItem] = []
    let contact = self.contacts.filter { (item) -> Bool in
      return item.address == lastUsed
    }.first ?? ContactItem(name: TransactionTitleHelper.title(from: lastUsed), address: lastUsed)

    let item = self.contactItem(with: contact, identifier: lastUsedCellIdentifier(item: contact))
    items = [item]
    return BaseTableSectionItem(identifier: "LastUsed", header: "LAST USED", items: items)
  }

  func contactItem(with item: ContactItem, identifier: String? = nil) -> ContactEntryTableViewCellItem {
    let contactItem = ContactEntryTableViewCellItem(reuseIdentifier: "ContactEntryTableViewCell",
                                                    identifier: identifier != nil ? (identifier ?? "") : self.cellIdentifierFor(item: item))
    contactItem.address = item.address
    contactItem.name = item.name
    if let address = item.address {
      contactItem.avatarURL = MinterMyAPIURL.avatarAddress(address: address).url()
    }
    return contactItem
  }

  func lastUsedCellIdentifier(item: ContactItem) -> String {
    return "LastUsed_\(String.random())"
  }

}
