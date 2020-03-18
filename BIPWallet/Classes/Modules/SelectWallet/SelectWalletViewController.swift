//
//  SelectWalletViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 25/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxAppState

class SelectWalletViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!

  // MARK: - ControllerProtocol

  typealias ViewModelType = SelectWalletViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SelectWalletViewModel) {
    //Input
    rx.viewDidLoad.map { _ in return Void() }
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.viewDidLoad)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.sections
      .bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)

    viewModel
      .output
      .sections
      .asDriver(onErrorJustReturn: []).drive(onNext: { [weak self] (sections) in
        let items = sections.first?.items.count ?? 0
        self?.tableHeightConstraint.constant = max(0, CGFloat(items) * 61)
        self?.view.layoutIfNeeded()
    }).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))

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

    configure(with: viewModel)
//    tableView.rx.setDelegate(self).disposed(by: disposeBag)

    dismissWhenTappedAround()

    viewModel.input.viewDidLoad.onNext(())
  }

  func registerCells() {
    tableView.register(UINib(nibName: "WalletCell", bundle: nil), forCellReuseIdentifier: "WalletCell")
    tableView.register(UINib(nibName: "AddWalletCell", bundle: nil), forCellReuseIdentifier: "AddWalletCell")
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    self.view.frame = self.tableView.frame
  }

}

class WeiredTableView: UITableView {

//  override var intrinsicContentSize: CGSize {
//    return contentSize
//  }

}
