//
//  DelegatedViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 10/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit

class DelegatedViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: -

  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var noContactsLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var warningView: UIView!

  let rightBarItem = UIBarButtonItem(image: UIImage(named: "ContactsAddButtonIcon"),
                                     landscapeImagePhone: nil,
                                     style: .plain,
                                     target: nil,
                                     action: nil)

  // MARK: - ControllerType

  var viewModel: ViewModelType!
  
  typealias ViewModelType = DelegatedViewModel

  func configure(with viewModel: DelegatedViewModel) {
    configureDefault()

    //Input
    self.rx.viewDidLoad.bind(to: viewModel.input.viewDidLoad).disposed(by: disposeBag)

    rightBarItem.rx.tap.asDriver().drive(viewModel.input.didTapAdd).disposed(by: disposeBag)

    //Output
    viewModel.output.sections
      .do(onNext: { [weak self] (items) in
        self?.noContactsLabel.alpha = items.count > 0 ? 0.0 : 1.0
      })
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)

    viewModel.output.isLoading.subscribe(onNext: { [weak self] (isLoading) in
      self?.activityIndicator.alpha = isLoading ? 1.0 : 0.0
      if isLoading {
        self?.activityIndicator.stopAnimating()
      } else {
        self?.activityIndicator.startAnimating()
      }
    }).disposed(by: disposeBag)

    tableView.rx.willDisplayCell
      .subscribe(viewModel.input.willDisplayCell)
      .disposed(by: disposeBag)

    viewModel.output.showKickedWarning.asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] val in
      self?.toggleTableFooterView(show: val)
    }).disposed(by: disposeBag)

    viewModel.input.viewDidLoad.onNext(())
  }

  // MARK: -

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  override func viewDidLoad() {
    super.viewDidLoad()

    activityIndicator.startAnimating()
    noContactsLabel.alpha = 0.0

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

    rightBarItem.tintColor = .mainPurpleColor()
    navigationItem.rightBarButtonItem = rightBarItem

    registerCells()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.navigationController?.navigationBar.backgroundColor = .white
    self.navigationController?.navigationBar.barTintColor = .white
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }

  override func willMove(toParent parent: UIViewController?) {
    if nil == parent {
      self.navigationController?.navigationBar.barTintColor = UIColor(hex: 0x2F1D69)
      self.navigationController?.navigationBar.barStyle = .default
      self.navigationController?.navigationBar.isTranslucent = false
    }

    super.willMove(toParent: parent)
  }

  func registerCells() {
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "DelegatedCoinTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "DelegatedCoinTableViewCell")
  }

  func toggleTableFooterView(show: Bool) {
    if show {
      tableView.tableFooterView = self.warningView
    } else {
      tableView.tableFooterView = nil
    }
  }

}

extension DelegatedViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 38
    }
    return 16
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.1
  }

}
