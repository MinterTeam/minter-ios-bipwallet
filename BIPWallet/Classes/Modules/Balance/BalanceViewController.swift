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

  var hardImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  // MARK: -

  var disposeBag = DisposeBag()
  var controllers = [UIViewController]()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: - IBOutlet

  @IBOutlet weak var balanceView: PassthroughView!
  @IBOutlet weak var balanceTitle: UILabel!
  @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var segmentedControlView: UIView!
  @IBOutlet weak var availableBalance: UILabel!
  @IBOutlet weak var delegatedBalanceTitle: UILabel!
  @IBOutlet weak var delegatedBalance: UILabel! {
    didSet {
      delegatedBalance.font = UIFont.semiBoldFont(of: 16.0)
    }
  }
  @IBOutlet weak var delegatedBalanceButton: UIButton!

  var walletSelectorButton = UIButton()
  let walletLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
  var walletSelectorView: UIView {
    let customView = UIView(frame: CGRect(x: 0, y: 0, width: 173, height: 100))
    walletLabel.isUserInteractionEnabled = false
    walletLabel.textColor = .white
    walletLabel.font = UIFont.boldFont(of: 18.0)
    let expandImageView = UIImageView(image: UIImage(named: "WalletsExpandImage")!)
    expandImageView.tintColor = .white
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

  lazy var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
      $0.reader = QRCodeReader(metadataObjectTypes: [.qr],
                               captureDevicePosition: .back)
      $0.showSwitchCameraButton = false
    }
    return QRCodeReaderViewController(builder: builder)
  }()

  // MARK: - ControllerProtocol

  typealias ViewModelType = BalanceViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: BalanceViewModel) {
    configureDefault()

    //Input
    walletSelectorButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapSelectWallet)
      .disposed(by: disposeBag)

    delegatedBalanceButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapDelegatedBalance)
      .disposed(by: disposeBag)

    shareItem.rx.tap.asDriver().drive(viewModel.input.didTapShare).disposed(by: disposeBag)
    scanQRItem.rx.tap.asDriver().drive(viewModel.input.didTapScanQR).disposed(by: disposeBag)

    Observable.of(self.availableBalance.rx.tapGesture(), self.balanceTitle.rx.tapGesture()).merge().when(.ended)
      .map {_ in}.subscribe(viewModel.input.didTapBalance).disposed(by: disposeBag)

    containerViewTap.filter { (recognizer) -> Bool in
      let point = recognizer.location(in: self.balanceView)
      return self.availableBalance.frame.contains(point) || self.balanceTitle.frame.contains(point)
    }.map {_ in}.subscribe(viewModel.input.didTapBalance).disposed(by: disposeBag)

    containerViewTap.filter { (recognizer) -> Bool in
      let point = recognizer.location(in: self.balanceView)

      let delegatedBalanceTitleFrame = self.delegatedBalanceTitle.frame.inset(by: UIEdgeInsets(top: -50, left: -50, bottom: -50, right: -50))
      let delegatedBalanceFrame = self.delegatedBalance.frame.inset(by: UIEdgeInsets(top: -50, left: -50, bottom: -50, right: -50))

      return delegatedBalanceTitleFrame.contains(point)
        || delegatedBalanceFrame.contains(point)
    }.map {_ in}.subscribe(viewModel.input.didTapDelegatedBalance).disposed(by: disposeBag)

    readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
      self?.readerVC.stopScanning()
      self?.readerVC.dismiss(animated: true) {
        if let res = result?.value {
          self?.viewModel.input.didScanQR.onNext(res)
        }
      }
    }

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
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] (val) in
        guard let `self` = self else { return }
        self.walletLabel.text = val
        let button = UIBarButtonItem(customView: self.walletSelectorView)
        self.navigationItem.setLeftBarButton(button, animated: true)
    }).disposed(by: disposeBag)

    viewModel.output.balanceTitle.asDriver(onErrorJustReturn: nil)
      .drive(self.balanceTitle.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.openAppSettings.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] (_) in
      self?.openAppSpecificSettings()
    }).disposed(by: disposeBag)
  }

  func configureDefault() {

    viewModel.impact.asDriver(onErrorJustReturn: .light).drive(onNext: { (type) in
      switch type {
      case .light:
        self.lightImpactFeedbackGenerator.prepare()
        self.lightImpactFeedbackGenerator.impactOccurred()

      case .hard:
        self.hardImpactFeedbackGenerator.prepare()
        self.hardImpactFeedbackGenerator.impactOccurred()
      }
    }).disposed(by: disposeBag)

    viewModel.sound.asDriver(onErrorJustReturn: .cancel).drive(onNext: { (type) in
      SoundHelper.playSoundIfAllowed(type: type)
    }).disposed(by: disposeBag)

    viewModel.showErrorMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performErrorNotification(title: message)
    }).disposed(by: disposeBag)

    viewModel.showSuccessMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performSuccessNotification(title: message)
    }).disposed(by: disposeBag)

    viewModel.showNotifyMessage.asDriver(onErrorJustReturn: "").drive(onNext: { (message) in
      BannerHelper.performNotifyNotification(title: message)
    }).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  let shareItem = UIBarButtonItem(image: UIImage(named: "ShareIcon"), style: .plain, target: nil, action: nil)
  let scanQRItem = UIBarButtonItem(image: UIImage(named: "ScanQRIcon"), style: .plain, target: nil, action: nil)

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel)

    segmentedControl.setFont(UIFont.semiBoldFont(of: 14.0))

    scanQRItem.tintColor = .white
    
    shareItem.tintColor = .white

    self.navigationItem.rightBarButtonItems = [scanQRItem, shareItem]
    
    scanQRItem.rx.tap.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      self.present(self.readerVC, animated: true, completion: nil)
    }).disposed(by: disposeBag)

    //HACK: to layout child view controllers
    view.layoutIfNeeded()
    self.setNeedsStatusBarAppearanceUpdate()
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

  lazy var containerViewTap = self.containerView.rx.tapGesture(configuration: { gesture, delegate in

    delegate.beginPolicy = .custom({ (gestureRecognizer) -> Bool in
      let point1 = gestureRecognizer.location(in: self.balanceView)
      let inBalance = self.availableBalance.frame.contains(point1) || self.balanceTitle.frame.contains(point1)

      let point2 = gestureRecognizer.location(in: self.balanceView)
      let inDelegated = self.delegatedBalanceTitle.frame.contains(point2) || self.delegatedBalance.frame.contains(point2)

      return (inBalance || inDelegated)
    })
  }).when(.ended).share()

  @objc func openAppSpecificSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else {
      return
    }

    UIApplication.shared.open(url, options: [:]) { (_) in
    }
  }

}
