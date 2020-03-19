//
//  ExchangeViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip

class ExchangeViewController: SegmentedPagerTabStripViewController, Controller, StoryboardInitializable {

  // MARK: - ControllerProtocol

  typealias ViewModelType = ExchangeViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ExchangeViewModel) {

  }

  // MARK: - ViewController

  var controllers = [UIViewController]()

  override func viewDidLoad() {

    self.title = "Convert Coins".localized()

//    settings.style.selectedBarHeight = 3
//    settings.style.buttonBarBackgroundColor = .white
//    settings.style.buttonBarHeight = 48.0
//    settings.style.buttonBarItemBackgroundColor = .white
//    settings.style.buttonBarItemFont = UIFont.boldFont(of: 14.0)
//    settings.style.buttonBarItemsShouldFillAvailiableWidth = true
//    settings.style.buttonBarItemTitleColor = UIColor.mainColor()
//    settings.style.selectedBarBackgroundColor = UIColor.mainColor()

//    changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?,
//      newCell: ButtonBarViewCell?,
//      progressPercentage: CGFloat,
//      changeCurrentIndex: Bool, animated: Bool) -> Void in
//
//      guard changeCurrentIndex == true else { return }
//
//      oldCell?.label.textColor = .black
//      newCell?.label.textColor = UIColor.mainColor()
//    }

    super.viewDidLoad()

    configure(with: viewModel)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: -

  override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
    return controllers
  }

}
