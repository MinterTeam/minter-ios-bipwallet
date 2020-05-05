//
//  ExchangeViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import XLPagerTabStrip

class ExchangeViewController: SegmentedPagerTabStripViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var lastBalanceButton: UIButton!

  // MARK: -

  var disposeBag = DisposeBag()

  // MARK: - ControllerProtocol

  typealias ViewModelType = ExchangeViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ExchangeViewModel) {
    //Input
    self.rx.viewDidDisappear
      .asDriver(onErrorJustReturn: false)
      .map({ (_) -> Void in
        return ()
      }).drive(self.viewModel.input.viewDidDisappear)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.lastUpdated
      .asDriver(onErrorJustReturn: nil)
      .drive(lastBalanceButton.rx.attributedTitle(for: .normal))
      .disposed(by: disposeBag)
  }
  
  func configureDefault() {

//    viewModel.impact.asDriver(onErrorJustReturn: .light).drive(onNext: { (type) in
//      switch type {
//      case .light:
//        self.lightImpactFeedbackGenerator.prepare()
//        self.lightImpactFeedbackGenerator.impactOccurred()
//
//      case .hard:
//        self.hardImpactFeedbackGenerator.prepare()
//        self.hardImpactFeedbackGenerator.impactOccurred()
//      }
//    }).disposed(by: disposeBag)
//
//    viewModel.sound.asDriver(onErrorJustReturn: .cancel).drive(onNext: { (type) in
//      SoundHelper.playSoundIfAllowed(type: type)
//    }).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  var controllers = [UIViewController]()

  override func viewDidLoad() {

    (view as? HandlerView)?.title = "Coin Exchange".localized()

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
