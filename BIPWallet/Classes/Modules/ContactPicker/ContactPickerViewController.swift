//
//  ContactPickerViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 28/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class ContactPickerViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  private let didTapEditOnCell = PublishSubject<IndexPath?>()
  private let didTapDeleteOnCell = PublishSubject<IndexPath?>()

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addItem: UIBarButtonItem!
  @IBOutlet weak var noContactsLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ContactPickerViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: ContactPickerViewModel) {
    configureDefault()

    //Input
    addItem.rx
      .tap
      .asDriver()
      .drive(viewModel.input.didTapAddContact)
      .disposed(by: disposeBag)

    self.rx
      .viewWillAppear
      .map { _ in Void() }
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)

    didTapEditOnCell.asDriver(onErrorJustReturn: nil)
      .drive(viewModel.input.editItem).disposed(by: disposeBag)

    didTapDeleteOnCell.asDriver(onErrorJustReturn: nil)
      .drive(viewModel.input.deleteItem).disposed(by: disposeBag)

    tableView.rx.modelSelected(BaseCellItem.self)
      .asDriver()
      .drive(viewModel.input.modelSelected)
      .disposed(by: disposeBag)

    //Output
    viewModel
      .output
      .sections
      .do(onNext: { [weak self] (items) in
        self?.noContactsLabel.alpha = items.count > 0 ? 0.0 : 1.0
      })
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)

    viewModel
      .output
      .scrollToCell
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] (indexPath) in
        if let indexPath = indexPath, let cell = self?.tableView.cellForRow(at: indexPath) {
          self?.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
          let currentBackgroundColor = cell.backgroundColor
          cell.backgroundColor = UIColor.mainGreyColor()
          UIView.animate(withDuration: 0.5) {
            cell.backgroundColor = currentBackgroundColor ?? UIColor.white
          }
        }
    }).disposed(by: disposeBag)

    viewModel.output.showError.asDriver(onErrorJustReturn: nil).drive(onNext: { (message) in
      BannerHelper.performCopiedNotification(title: message)
    }).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)

    addItem.tintColor = UIColor.mainPurpleColor()
    tableView.rx.setDelegate(self).disposed(by: disposeBag)

    rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
                                                                  reloadAnimation: .none,
                                                                  deleteAnimation: .automatic)

    rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
      configureCell: { dataSource, tableView, indexPath, sm in

        guard let item = try? dataSource.model(at: indexPath) as? BaseCellItem,
          let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
          return UITableViewCell()
        }
        cell.configure(item: item)
        return cell
      }, canEditRowAtIndexPath: { _,_ in
        return true
      })

    configure(with: viewModel)

    registerCells()
    self.isEditing = true
  }

  // MARK: -

}

extension ContactPickerViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard (rxDataSource?.sectionModels[section].header?.count ?? 0) > 0 else {
      return nil
    }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ContactPickerHeader") as? ContactPickerHeader
    view?.titleLabel?.text = rxDataSource?.sectionModels[section].header
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if (rxDataSource?.sectionModels[section].header?.count ?? 0) > 0 {
      return 38
    }
    return 0.1
  }

  func tableView(_ tableView: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let modifyAction = UIContextualAction(style: .normal, title:  "", handler: { [weak self] (ac: UIContextualAction, view: UIView, success:(Bool) -> Void) in
      self?.didTapEditOnCell.onNext(indexPath)
      success(true)
    })
    modifyAction.backgroundColor = UIColor.mainPurpleColor()
    modifyAction.image = UIImage(named: "ContactsEditIcon")

    let deleteAction = UIContextualAction(style: .destructive, title: "", handler: { [weak self] (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
      self?.didTapDeleteOnCell.onNext(indexPath)
      success(true)
    })
    deleteAction.backgroundColor = UIColor.tableViewCellActionRedColor()
    deleteAction.image = UIImage(named: "ContactsDeleteIcon")

    return UISwipeActionsConfiguration(actions: [deleteAction, modifyAction])
  }

  func tableView(_ tableView: UITableView,
    editingStyleForRowAt indexPath: IndexPath)
    -> UITableViewCell.EditingStyle {
      return .none
  }

}

extension ContactPickerViewController {

  func registerCells() {
    tableView.register(UINib(nibName: "ContactPickerHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "ContactPickerHeader")
    tableView.register(UINib(nibName: "ContactEntryTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ContactEntryTableViewCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
  }
}
