//
//  SettingsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SettingsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var logoutItem: UIBarButtonItem!
  @IBOutlet weak var footer: UIView!

  // MARK: - ControllerProtocol

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  typealias ViewModelType = SettingsViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: SettingsViewModel) {
    //Output
    viewModel.output.sections
      .bind(to: tableView.rx.items(dataSource: rxDataSource!))
      .disposed(by: disposeBag)

    self.rx.viewWillAppear.asDriver(onErrorJustReturn: false).map { _ in }
      .drive(viewModel.input.viewWillAppear).disposed(by: disposeBag)

    tableView.rx.modelSelected(BaseCellItem.self).asDriver()
      .drive(viewModel.input.didSelectModel)
      .disposed(by: disposeBag)

    logoutItem.rx.tap.asDriver()
      .drive(viewModel.input.didTapLogout)
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    registerCells()

    footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
    self.tableView.tableFooterView = footer

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

  private func registerCells() {
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "DisclosureTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "DisclosureTableViewCell")
    tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ButtonTableViewCell")
    tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "BlankTableViewCell")
    tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SwitchTableViewCell")
    tableView.register(UINib(nibName: "ContactPickerHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "ContactPickerHeader")
  }

}

extension SettingsViewController: UITableViewDelegate {

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
      return 46
    }
    return 0.1
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.1
  }

}
