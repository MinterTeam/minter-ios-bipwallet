//
//  CoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import XLPagerTabStrip
import RxAppState
import SnapKit

class CoinsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!

  // MARK: - ControllerProtocol

  typealias ViewModelType = CoinsViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: CoinsViewModel) {
    configureDefault()

    //Input
    self.rx.viewDidLoad.asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewDidLoad)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.sections
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    registerCells()

    rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
                                                                  reloadAnimation: .none,
                                                                  deleteAnimation: .automatic)

    tableView.rx.setDelegate(self).disposed(by: disposeBag)

    rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
      configureCell: { dataSource, tableView, indexPath, sm in

        guard let item = try? dataSource.model(at: indexPath) as? BaseCellItem,
          let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
          return UITableViewCell()
        }
        cell.configure(item: item)
        return cell
      })

    configure(with: viewModel)
  }

}

extension CoinsViewController: IndicatorInfoProvider {
  func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: "Coins")
  }
}

extension CoinsViewController {

  func registerCells() {
    tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "DefaultHeader")
    tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ButtonTableViewCell")
    tableView.register(UINib(nibName: "CoinTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "CoinTableViewCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "LoadingTableViewCell")
  }
}

extension CoinsViewController: UITableViewDelegate {

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
