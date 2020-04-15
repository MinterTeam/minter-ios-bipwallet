//
//  AllTransactionsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class AllTransactionsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var noTransactionsLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var filterAll: UIButton!
  @IBOutlet weak var filterIncoming: UIButton!
  @IBOutlet weak var filterOutgoing: UIButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = AllTransactionsViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: AllTransactionsViewModel) {
    //Input
    self.rx.viewWillAppear.map {_ in Void() }
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)

    tableView.rx.itemSelected.asDriver()
      .drive(viewModel.input.didSelectItem)
      .disposed(by: disposeBag)

    filterAll.rx.tap.asDriver().drive(viewModel.input.filterAllTaped).disposed(by: disposeBag)
    filterIncoming.rx.tap.asDriver().drive(viewModel.input.filterIncomingTaped).disposed(by: disposeBag)
    filterOutgoing.rx.tap.asDriver().drive(viewModel.input.filterOutgoingTaped).disposed(by: disposeBag)

    tableView.rx.willDisplayCell
      .asDriver()
      .drive(viewModel.input.willDisplayCell)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.sections
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)

    viewModel.output.showNoTransactions.map { $0 ? 1.0 : 0.0 }
      .asDriver(onErrorJustReturn: 0.0).drive(noTransactionsLabel.rx.alpha)
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    filterAll.rx.tap.do(onNext: { (_) in
      self.filterAll.isSelected = true
      self.filterIncoming.isSelected = false
      self.filterOutgoing.isSelected = false
    }).subscribe().disposed(by: disposeBag)

    filterIncoming.rx.tap.do(onNext: { (_) in
      self.filterIncoming.isSelected = true
      self.filterAll.isSelected = false
      self.filterOutgoing.isSelected = false
    }).subscribe().disposed(by: disposeBag)

    filterOutgoing.rx.tap.do(onNext: { (_) in
      self.filterOutgoing.isSelected = true
      self.filterAll.isSelected = false
      self.filterIncoming.isSelected = false
    }).subscribe().disposed(by: disposeBag)

    registerCells()

    rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .fade,
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
    })

    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    configure(with: viewModel)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.navigationController?.navigationBar.backgroundColor = .white
    self.navigationController?.navigationBar.barTintColor = .white
  }

}

extension AllTransactionsViewController {

  func registerCells() {
    tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "DefaultHeader")
    tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ButtonTableViewCell")
    tableView.register(UINib(nibName: "TransactionCell", bundle: nil),
                       forCellReuseIdentifier: "TransactionCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "LoadingTableViewCell")
  }
}

extension AllTransactionsViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard (rxDataSource?.sectionModels[section].header?.count ?? 0) > 0 else {
      return nil
    }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader") as? DefaultHeader
    view?.titleLabel?.text = rxDataSource?.sectionModels[section].header
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if (rxDataSource?.sectionModels[section].header?.count ?? 0) > 0 {
      return 46
    }
    return 0.1
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.1
  }

}
