//
//  TransactionsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import XLPagerTabStrip
import RxAppState

class TransactionsViewController: BaseViewController, Controller, StoryboardInitializable {

  @IBOutlet weak var noTransactionsLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!

  // MARK: - ControllerProtocol

  typealias ViewModelType = TransactionsViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: TransactionsViewModel) {
    //Input
    self.rx.viewDidLoad
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewDidLoad)
      .disposed(by: disposeBag)

    tableView.rx.itemSelected.asDriver()
      .drive(viewModel.input.didSelectItem)
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

    registerCells()

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
    })

    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    configure(with: viewModel)

    tableView.contentInset = UIEdgeInsets(top: 230, left: 0, bottom: 0, right: 0)
  }
}

extension TransactionsViewController: IndicatorInfoProvider {
  func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: "Transactions")
  }
}

extension TransactionsViewController {

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

extension TransactionsViewController: UITableViewDelegate {

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
