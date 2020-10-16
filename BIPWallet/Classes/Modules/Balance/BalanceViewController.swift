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

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var balanceView: UIView!
  @IBOutlet weak var balanceTitle: UILabel!
  @IBOutlet weak var segmentedControlView: UIView!
  @IBOutlet weak var availableBalance: UILabel!
  @IBOutlet weak var delegatedBalanceTitle: UILabel!
  @IBOutlet weak var delegatedBalance: UILabel! {
    didSet {
      delegatedBalance.font = UIFont.semiBoldFont(of: 16.0)
    }
  }
  @IBOutlet weak var delegatedBalanceButton: UIButton!
  @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!

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

    Observable.of(availableBalance.rx.tapGesture(), balanceTitle.rx.tapGesture()).merge().when(.ended)
      .map {_ in}.subscribe(viewModel.input.didTapBalance).disposed(by: disposeBag)

    Observable.of(delegatedBalanceTitle.rx.tapGesture(), delegatedBalance.rx.tapGesture()).merge().when(.ended)
      .map {_ in}.subscribe(viewModel.input.didTapDelegatedBalance).disposed(by: disposeBag)

    readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
      self?.readerVC.stopScanning()
      self?.readerVC.dismiss(animated: true) {
        if let res = result?.value {
          self?.viewModel.input.didScanQR.onNext(res)
        }
      }
    }

    self.refreshControl?.rx.controlEvent(.valueChanged)
      .asDriver().drive(onNext: { [weak self] (_) in
//        self?.refreshControl?.beginRefreshing()
        self?.viewModel.input.didRefresh.onNext(())
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          self?.refreshControl?.endRefreshing()
        }
      }).disposed(by: disposeBag)

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
      .drive(balanceTitle.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.openAppSettings.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] (_) in
      self?.openAppSpecificSettings()
    }).disposed(by: disposeBag)
  }

  func configureDefault() {

    viewModel.impact.asDriver(onErrorJustReturn: .light).drive(onNext: { [weak self] (type) in
      switch type {
      case .light:
        self?.lightImpactFeedbackGenerator.prepare()
        self?.lightImpactFeedbackGenerator.impactOccurred()

      case .hard:
        self?.hardImpactFeedbackGenerator.prepare()
        self?.hardImpactFeedbackGenerator.impactOccurred()
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

  var refreshControl: UIRefreshControl?

  override func viewDidLoad() {
    super.viewDidLoad()

    refreshControl = UIRefreshControl()
    refreshControl?.translatesAutoresizingMaskIntoConstraints = false
    refreshControl?.tintColor = .white

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(self.refreshControl!)

    refreshControl?.snp.makeConstraints { (maker) in
      maker.top.equalTo(self.scrollView).offset(-50)
      maker.centerX.equalTo(self.scrollView)
      maker.width.height.equalTo(30)
    }

    segmentedControl.setFont(UIFont.semiBoldFont(of: 14.0))

    scanQRItem.tintColor = .white
    shareItem.tintColor = .white

    navigationItem.rightBarButtonItems = [scanQRItem, shareItem]

    scanQRItem.rx.tap.subscribe(onNext: { [weak self] (_) in
      guard let `self` = self else { return }
      self.present(self.readerVC, animated: true, completion: nil)
    }).disposed(by: disposeBag)

    configure(with: viewModel)

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

  @objc func openAppSpecificSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else {
      return
    }

    UIApplication.shared.open(url, options: [:]) { (_) in}
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let maxHeight = max(controllers.map {
      ($0.view.subviews.first { (view) -> Bool in
        return view is UITableView
      } as? UITableView)?.contentSize.height ?? 0.0
    }.max() ?? 0.0, 500.0)

    if scrollViewHeightConstraint.constant != maxHeight {
      scrollViewHeightConstraint.constant = maxHeight
    }
  }

}

extension BalanceViewController: UICollectionViewDelegate, UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let item = collectionView.dequeueReusableCell(withReuseIdentifier: "IGStoryPreviewCell", for: indexPath)
    item.backgroundColor = .red
    return item
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let storyDict: [String: Any] = [
      "data": ["id":3,
        "title":"Test2",
        "icon":"https://image.minter.network/minter-stories/icon/3",
        "weight":1,
        "is_active":true,
        "created_at":"2020-09-28T10:44:06.075043Z",
        "slides": [
          ["id":1,"story_id":1,"weight":0,"title":"test","file":"https://image.minter.network/minter-stories/2/slide/1","link":"https://minter.network","created_at":"2020-09-28T10:46:30.969621Z"],
          ["id":2,"story_id":2,"weight":0,"title":"test","file":"https://image.minter.network/minter-stories/2/slide/1","link":"https://minter.network","created_at":"2020-09-28T10:46:30.969621Z"]
        ]
      ]
    ]
    let story = IGStory(id: "1", icon: "https://image.minter.network/minter-stories/icon/3", slides: [
      IGSnap(id: "1", storyId: 1, title: "trololo", file: "https://image.minter.network/minter-stories/2/slide/1", url: "https://image.minter.network/minter-stories/2/slide/1"),
      IGSnap(id: "2", storyId: 1, title: "trololo", file: "https://image.minter.network/minter-stories/2/slide/1", url: "https://user-images.githubusercontent.com/16580898/31142698-bc93677e-a883-11e7-97ff-7a298665a406.png"),
      IGSnap(id: "3", storyId: 1, title: "trololo", file: "https://image.minter.network/minter-stories/2/slide/1", url: "https://image.minter.network/minter-stories/2/slide/1")
    ])
    let story2 = IGStory(id: "2", icon: "https://image.minter.network/minter-stories/icon/3", slides: [
      IGSnap(id: "1", storyId: 1, title: "trololo", file: "https://image.minter.network/minter-stories/2/slide/1", url: "https://user-images.githubusercontent.com/16580898/31142698-bc93677e-a883-11e7-97ff-7a298665a406.png")
    ])

    let stories = [story, story2]

//    let stories = (try? IGMockLoader.loadAPIResponse(response: storyDict))?.otherStories ?? []
    let storyPreviewScene = IGStoryPreviewController(layout: .cubic, stories: stories, handPickedStoryIndex: 0, handPickedSnapIndex: 0)
    storyPreviewScene.modalPresentationStyle = .fullScreen
    self.present(storyPreviewScene, animated: true, completion: nil)
  }

}
