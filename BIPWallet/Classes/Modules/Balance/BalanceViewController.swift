import UIKit
import RxSwift
import XLPagerTabStrip
import SnapKit
import RxDataSources

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

  @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var balanceView: UIView!
  @IBOutlet weak var balanceTitle: UILabel!
  @IBOutlet weak var availableBalance: UILabel!
  @IBOutlet weak var delegatedBalanceTitle: UILabel!
  @IBOutlet weak var delegatedBalance: UILabel! {
    didSet {
      delegatedBalance.font = UIFont.semiBoldFont(of: 16.0)
    }
  }
  @IBOutlet weak var delegatedBalanceButton: UIButton!
  @IBOutlet weak var segmentedControlView: UIView!
  @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!

  var walletSelectorButton = UIButton()
  let walletLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
  let walletAddressLabel = UILabel(frame: CGRect(x: 0, y: 31, width: 200, height: 16))
  lazy var walletSelectorView: UIView = {
    let customView = UIView(frame: CGRect(x: 17, y: 0, width: 200, height: 41))
//    walletLabel.isUserInteractionEnabled = false
    walletLabel.textColor = .white
    walletLabel.font = UIFont.boldFont(of: 18.0)
    let image = UIImage(named: "WalletsExpandImage")!.withRenderingMode(.alwaysTemplate)
    let expandImageView = UIImageView(image: image)
    expandImageView.tintColor = .white
//    expandImageView.isUserInteractionEnabled = false
    customView.addSubview(walletLabel)
    customView.addSubview(expandImageView)

    walletAddressLabel.translatesAutoresizingMaskIntoConstraints = false
    walletAddressLabel.textColor = UIColor(hex: 0xFFFFFF, alpha: 0.7)
    walletAddressLabel.font = UIFont.semiBoldFont(of: 13.0)
    customView.addSubview(walletAddressLabel)

    walletLabel.snp.makeConstraints { (maker) in
      maker.top.equalTo(customView).offset(9)
      maker.left.equalTo(customView)
      maker.height.equalTo(21)
//      maker.right.equalTo(customView)
    }

    walletAddressLabel.snp.makeConstraints { (maker) in
      maker.top.equalTo(walletLabel.snp.bottom).offset(1)
      maker.left.equalTo(customView).offset(31)
      maker.height.equalTo(16)
//      maker.right.equalTo(customView)
    }

    expandImageView.snp.makeConstraints { (maker) in
      maker.centerY.equalTo(walletLabel)
//      maker.left.equalTo(walletLabel.snp.right).offset(15)
      maker.right.greaterThanOrEqualTo(walletAddressLabel.snp.right).offset(15)
      maker.right.greaterThanOrEqualTo(walletLabel.snp.right).offset(15)
    }
//    customView.isUserInteractionEnabled = false
//    customView.addSubview(walletSelectorButton)
//    walletSelectorButton.snp.makeConstraints { (maker) in
//      maker.top.left.right.bottom.equalTo(customView)
//    }

    self.rx.viewWillDisappear.subscribe(onNext: { [weak self] (animated) in
      if animated {
        UIView.animate(withDuration: 0.1) {
          self?.walletSelectorView.alpha = 0.0
        }
      } else {
        self?.walletSelectorView.alpha = 0.0
      }
    }).disposed(by: disposeBag)

    self.rx.viewDidAppear.subscribe(onNext: { [weak self] (animated) in
      if animated {
        UIView.animate(withDuration: 0.1) {
          self?.walletSelectorView.alpha = 1.0
        }
      } else {
        self?.walletSelectorView.alpha = 1.0
      }
    }).disposed(by: disposeBag)

    self.scrollView.rx.contentOffset.subscribe(onNext: { (point) in

      self.walletAddressLabel.alpha = min(1, max(0, -0.03*point.y + 1))
      if point.y > 33 {
        self.walletAddressLabel.alpha = 0.0
      }
    }).disposed(by: disposeBag)

    return customView
  }()

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
    walletSelectorView.rx.tapGesture().when(.ended).map { _ in }
    .subscribe(viewModel.input.didTapSelectWallet)
    .disposed(by: disposeBag)

    delegatedBalanceButton.rx.tap
      .asDriver()
      .drive(viewModel.input.didTapDelegatedBalance)
      .disposed(by: disposeBag)

    collectionView.rx.itemSelected.subscribe(viewModel.input.didTapStory).disposed(by: disposeBag)

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

    refreshControl?.rx.controlEvent(.valueChanged)
      .asDriver().drive(onNext: { [weak self] (_) in
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
      .asDriver(onErrorJustReturn: nil)
      .drive(walletLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.address.distinctUntilChanged()
      .subscribe(walletAddressLabel.rx.text).disposed(by: disposeBag)

    viewModel.output.balanceTitle.asDriver(onErrorJustReturn: nil)
      .drive(balanceTitle.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.openAppSettings.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] (_) in
      self?.openAppSpecificSettings()
    }).disposed(by: disposeBag)

    viewModel.output.stories.do(onNext: { [unowned self] (items) in
      if items.count > 0 {
        self.showStories()
      } else {
        self.hideStories()
      }
    })
    .bind(to: collectionView.rx.items(dataSource: rxDataSource!))
    .disposed(by: disposeBag)
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

  var rxDataSource: RxCollectionViewSectionedAnimatedDataSource<BaseTableSectionItem>?

  // MARK: - ViewController

  let shareItem = UIBarButtonItem(image: UIImage(named: "ShareIcon"), style: .plain, target: nil, action: nil)
  let scanQRItem = UIBarButtonItem(image: UIImage(named: "ScanQRIcon"), style: .plain, target: nil, action: nil)

  var refreshControl: UIRefreshControl?

  override func viewDidLoad() {
    super.viewDidLoad()

    hideStories()

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

    collectionView.register(UINib(nibName: "StoryCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "StoryCollectionViewCell")

    rxDataSource = RxCollectionViewSectionedAnimatedDataSource<BaseTableSectionItem>(
      configureCell: { dataSource, tableView, indexPath, sm in

        guard let item = try? dataSource.model(at: indexPath) as? BaseCellItem,
              let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier, for: indexPath) as? Configurable & UICollectionViewCell else {
          return UICollectionViewCell()
        }
        cell.configure(item: item)
        return cell
    })

    rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
                                                                  reloadAnimation: .none,
                                                                  deleteAnimation: .automatic)

    configure(with: viewModel)

    //HACK: to layout child view controllers
    view.layoutIfNeeded()
    self.setNeedsStatusBarAppearanceUpdate()

    navigationController?.navigationBar.addSubview(self.walletSelectorView)

    self.navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleBackPopGesture(gesture:)))
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = UIColor(hex: 0x2F1D69)
      appearance.titleTextAttributes = [
        NSAttributedString.Key.font: UIFont.defaultFont(of: 14),
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.baselineOffset: 1
      ]
      let img = UIImage(named: "BackButtonIcon")!
        .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0))
      img.stretchableImage(withLeftCapWidth: 0, topCapHeight: 20)
      appearance.setBackIndicatorImage(img, transitionMaskImage: img)

      navigationController?.navigationBar.standardAppearance = appearance
      navigationController?.navigationBar.scrollEdgeAppearance = appearance
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

extension BalanceViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return .init(width: 96, height: 96)
  }

  func showStories() {
    collectionViewBottomConstraint.constant = 24
    collectionViewHeightConstraint.constant = 96
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
  }

  func hideStories() {
    collectionViewBottomConstraint.constant = 0
    collectionViewHeightConstraint.constant = 0
  }

}

extension BalanceViewController: UIGestureRecognizerDelegate {

  @objc func handleBackPopGesture(gesture: UIGestureRecognizer) {
    let progress = (gesture.location(in: view).x / view.bounds.width)
    walletSelectorView.alpha = progress
  }

}
