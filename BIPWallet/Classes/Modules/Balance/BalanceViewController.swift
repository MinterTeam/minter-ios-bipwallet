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

  @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var segmentedControlView: UIView!
  @IBOutlet weak var availableBalance: UILabel!
  @IBOutlet weak var delegatedBalance: UILabel!
  @IBOutlet weak var delegatedBalanceButton: UIButton!

  var walletSelectorButton = UIButton()
  let walletLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
  var walletSelectorView: UIView {
    let customView = UIView(frame: CGRect(x: 0, y: 0, width: 173, height: 100))
    walletLabel.isUserInteractionEnabled = false
    walletLabel.textColor = .white
    walletLabel.font = UIFont.semiBoldFont(of: 18.0)
    let expandImageView = UIImageView(image: UIImage(named: "WalletsExpandImage")!)
    expandImageView.isUserInteractionEnabled = false
    customView.addSubview(walletLabel)
    customView.addSubview(expandImageView)

    walletLabel.snp.makeConstraints { (maker) in
      maker.top.equalTo(customView).offset(9)
      maker.left.equalTo(customView)
      maker.height.equalTo(21)
      maker.right.equalTo(customView).offset(-25)
    }
    expandImageView.snp.makeConstraints { (maker) in
      maker.centerY.equalTo(walletLabel)
      maker.left.equalTo(walletLabel.snp.right).offset(15)
    }
    customView.isUserInteractionEnabled = false
    customView.addSubview(walletSelectorButton)
    walletSelectorButton.snp.makeConstraints { (maker) in
      maker.top.left.right.bottom.equalTo(customView)
    }
    return customView
  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = BalanceViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: BalanceViewModel) {
    //Input
    walletSelectorButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapSelectWallet)
      .disposed(by: disposeBag)

    delegatedBalanceButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapDelegatedBalance)
      .disposed(by: disposeBag)

    //Output
    viewModel.output
      .availabaleBalance
      .asDriver(onErrorJustReturn: NSAttributedString())
      .drive(availableBalance.rx.attributedText)
      .disposed(by: disposeBag)

    viewModel.output
      .delegatedBalance
      .asDriver(onErrorJustReturn: "")
      .drive(delegatedBalance.rx.text)
      .disposed(by: disposeBag)

    viewModel.output
      .wallet
      .subscribe(onNext: { [weak self] (val) in
        guard let `self` = self else { return }
        self.walletLabel.text = val
        let button = UIBarButtonItem(customView: self.walletSelectorView)
        self.navigationItem.setLeftBarButton(button, animated: true)
    }).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)

    segmentedControl.setFont(UIFont.semiBoldFont(of: 14.0))

    //HACK: to layout child view controllers
    view.layoutIfNeeded()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.navigationController?.navigationBar.barTintColor = UIColor(hex: 0x2F1D69)
    self.navigationController?.navigationBar.barStyle = .default
    self.navigationController?.navigationBar.isTranslucent = false
  }

  override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
    return controllers
  }

}
