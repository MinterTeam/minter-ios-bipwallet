//
//  TransactionViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 02/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class TransactionViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var tableView: UITableView!
//  {
//    didSet {
//      tableView.rowHeight = UITableView.automaticDimension
//    }
//  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = TransactionViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: TransactionViewModel) {
    //Input
    self.rx.viewWillAppear.map { _ in Void() }
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)

    self.rx.viewDidDisappear.map { _ in Void() }
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewDidDisappear)
      .disposed(by: disposeBag)

//    tableView.rx.itemSelected.asDriver()
//      .drive(viewModel.input.didSelectItem)
//      .disposed(by: disposeBag)

    //Output
    viewModel
      .output
      .sections
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    (view as? HandlerView)?.title = "Transaction".localized()

    tableView.tableFooterView = UIView()

    registerCells()

    rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
                                                                  reloadAnimation: .none,
                                                                  deleteAnimation: .automatic)

    rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
      configureCell: { [weak self] dataSource, tableView, indexPath, sm in

        guard let item = try? dataSource.model(at: indexPath) as? BaseCellItem,
          let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
          return UITableViewCell()
        }
        cell.configure(item: item)
        return cell
    })

//    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    configure(with: viewModel)
  }

}

extension TransactionViewController {

  func registerCells() {
    tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "DefaultHeader")
    tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ButtonTableViewCell")
    tableView.register(UINib(nibName: "TransactionAddressCell", bundle: nil),
                       forCellReuseIdentifier: "TransactionAddressCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "LoadingTableViewCell")
    tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "BlankTableViewCell")
    tableView.register(UINib(nibName: "TransactionKeyValueCell", bundle: nil),
                       forCellReuseIdentifier: "TransactionKeyValueCell")
    tableView.register(UINib(nibName: "TransactionTwoColumnCell", bundle: nil),
                       forCellReuseIdentifier: "TransactionTwoColumnCell")
  }
}
