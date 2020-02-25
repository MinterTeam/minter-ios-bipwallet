//
//  BalanceViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip
import SnapKit

class BalanceViewController: SegmentedPagerTabStripViewController, Controller, StoryboardInitializable {

  // MARK: -

  var disposeBag = DisposeBag()
  var controllers = [UIViewController]()

  // MARK: - IBOutlet

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var segmentedControlView: UIView!

  // MARK: - ControllerProtocol

  typealias ViewModelType = BalanceViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: BalanceViewModel) {

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)

    segmentedControl.setFont(UIFont.semiBoldFont(of: 14.0))

    self.navigationController?.navigationBar.barTintColor = UIColor(hex: 0x2F1D69)
    self.navigationController?.navigationBar.barStyle = .default
    self.navigationController?.navigationBar.isTranslucent = false

    let customView = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
    customView.textColor = .white
    customView.text = "🐠 Main Wallet ,"

    let item = UIBarButtonItem(customView: customView)

    navigationController?.navigationItem.leftBarButtonItem = item
    navigationItem.leftBarButtonItem = item

    //HACK: to layout child view controllers
    view.layoutIfNeeded()
  }

  override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
    return controllers
  }

}
