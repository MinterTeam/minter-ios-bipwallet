//
//  ValidatorsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class ValidatorsViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var noDataLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ValidatorsViewModel

  var viewModel: ViewModelType!

  var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  func configure(with viewModel: ValidatorsViewModel) {
      configureDefault()

      //Input
//      self.rx.viewWillAppear.map { _ in Void() }.asDriver(onErrorJustReturn: ())
//        .drive(viewModel.input.viewWillAppear)
//        .disposed(by: disposeBag)

      tableView.rx.modelSelected(BaseCellItem.self).asDriver()
        .drive(viewModel.input.modelSelected)
        .disposed(by: disposeBag)

      //Output
      viewModel.output.sections
        .do(onNext: { [weak self] (items) in
          self?.noDataLabel.alpha = items.count > 0 ? 0.0 : 1.0
        })
        .bind(to: tableView.rx.items(dataSource: rxDataSource!))
        .disposed(by: disposeBag)

    }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
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
  }

}

extension ValidatorsViewController: UITableViewDelegate {

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
}

extension ValidatorsViewController {

  func registerCells() {
    tableView.register(UINib(nibName: "ContactPickerHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "ContactPickerHeader")
    tableView.register(UINib(nibName: "ValidatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ValidatorTableViewCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
  }
}
