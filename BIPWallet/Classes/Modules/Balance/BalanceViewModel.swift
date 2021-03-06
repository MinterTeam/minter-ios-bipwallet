//
//  BalanceViewModel.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import RxReachability
import Reachability
import AVFoundation

class BalanceViewModel: BaseViewModel, ViewModel, WalletSelectableViewModel {

  typealias BalanceHeaderItem = (title: String?, text: NSAttributedString?, animated: Bool)

  enum BalanceType: String {
    case balanceBIP
    case totalBalanceBIP
    case totalBalanceUSD
  }

  lazy var changedBalanceTypeSubject = BehaviorSubject<BalanceType>(value: BalanceType(rawValue: self.dependency.appSettingsSerivce.balanceType) ?? .balanceBIP)

  // MARK: -

  private var reachability = Reachability()
  private let needsToUpdateBalance = PublishSubject<Void>()
  private let availableBalance = PublishSubject<NSAttributedString>()
  private let delegatedBalance = PublishSubject<String>()
  private let didTapSelectWallet = PublishSubject<Void>()
  private let didTapDelegatedBalance = PublishSubject<Void>()
  private let didTapBalance = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let didScanQR = PublishSubject<String?>()
  private let didTapScanQR = PublishSubject<Void>()
  let didTapStory = PublishSubject<IndexPath>()
  private let openAppSettingsSubject = PublishSubject<Void>()
  private let balanceTitle = PublishSubject<String?>()
  let didRefresh = PublishSubject<Void>()
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.timer(0, period: 0.5, scheduler: MainScheduler.instance).map {_ in}, self.changedBalanceTypeSubject.map {_ in}).merge()
  let storiesSubject = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
  let forceUpdateStories = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: BalanceViewModel.Input!
  var output: BalanceViewModel.Output!
  var dependency: BalanceViewModel.Dependency!

  struct Input {
    var needsToUpdateBalance: AnyObserver<Void>
    var didTapSelectWallet: AnyObserver<Void>
    var didTapDelegatedBalance: AnyObserver<Void>
    var didTapBalance: AnyObserver<Void>
    var didTapShare: AnyObserver<Void>
    var didScanQR: AnyObserver<String?>
    var didTapScanQR: AnyObserver<Void>
    var didRefresh: AnyObserver<Void>
    var didTapStory: AnyObserver<IndexPath>
  }

  struct Output {
    var availabaleBalance: Observable<NSAttributedString>
    var delegatedBalance: Observable<String>
    var didTapSelectWallet: Observable<Void>
    var wallet: Observable<String?>
    var address: Observable<String?>
    var showDelegated: Observable<Void>
    var balanceTitle: Observable<String?>
    var didTapShare: Observable<Void>
    var didScanQR: Observable<String?>
    var openAppSettings: Observable<Void>
    var stories: Observable<[BaseTableSectionItem]>
  }

  struct Dependency {
    var balanceService: BalanceService
    var appSettingsSerivce: AppSettings
    var coinService: CoinService
    var storiesService: StoriesService
    var appSettings: AppSettings
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(needsToUpdateBalance: needsToUpdateBalance.asObserver(),
                       didTapSelectWallet: didTapSelectWallet.asObserver(),
                       didTapDelegatedBalance: didTapDelegatedBalance.asObserver(),
                       didTapBalance: didTapBalance.asObserver(),
                       didTapShare: didTapShare.asObserver(),
                       didScanQR: didScanQR.asObserver(),
                       didTapScanQR: didTapScanQR.asObserver(),
                       didRefresh: didRefresh.asObserver(),
                       didTapStory: didTapStory.asObserver()
    )

    self.output = Output(availabaleBalance: availableBalance.asObservable(),
                         delegatedBalance: delegatedBalance.asObservable(),
                         didTapSelectWallet: didTapSelectWallet.map { $0 },
                         wallet: walletTitleObservable(),
                         address: walletAddress(),
                         showDelegated: didTapDelegatedBalance.asObservable(),
                         balanceTitle: balanceTitle.asObservable(),
                         didTapShare: didTapShare.asObservable(),
                         didScanQR: didScanQR.asObservable(),
                         openAppSettings: openAppSettingsSubject.asObservable(),
                         stories: storiesSubject
    )

    bind()

    try? reachability?.startNotifier()
  }

  private func walletAddress() -> Observable<String?> {
    return Observable.combineLatest(walletTitleObservable(), walletAddressObservable()).map { val in
      let candidatAddress = TransactionTitleHelper.title(from: val.1 ?? "")
      guard false == val.0?.contains(candidatAddress) else { return "" }

      return candidatAddress
    }
  }

  // MARK: -

  func bind() {

    //Change balance type when lastBlockAgo info appears or on type change
    balanceTitleObservable.withLatestFrom(Observable.combineLatest(balanceService.lastBlockAgo(), changedBalanceTypeSubject)).map { lastBlockAgo, balanceType -> String in
     let ago = Date().timeIntervalSince1970 - (lastBlockAgo ?? 0)
     return self.headerViewLastUpdatedTitleText(balanceType: balanceType, seconds: ago)
    }.subscribe(balanceTitle).disposed(by: disposeBag)

    //Setting balance for the first time after load
    dependency.balanceService.balances().withLatestFrom(changedBalanceTypeSubject) { [weak self] balances, balanceType in
      return self?.balanceHeaderText(balanceType: balanceType, balances: balances)
    }.subscribe(onNext: { val in
      self.balanceTitle.onNext(val?.title)
      self.availableBalance.onNext(val?.text ?? NSAttributedString())
    }).disposed(by: disposeBag)

    dependency.balanceService.account.withLatestFrom(changedBalanceTypeSubject).subscribe(onNext: { (type) in
      let val = self.balanceHeaderItem(balanceType: .balanceBIP, balance: 0.0, isUSD: type == .totalBalanceUSD)
      self.availableBalance.onNext(val.text ?? NSAttributedString())
    }).disposed(by: disposeBag)

    //Showing delegated balance
    dependency.balanceService.delegatedBalance().subscribe(onNext: { (val) in
      let balance = val.2 ?? 0
      var str = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: CurrencyNumberFormatter.coinFormatter)
      str += " "
      str += Coin.baseCoin().symbol!
      self.delegatedBalance.onNext(str)
    }).disposed(by: disposeBag)

    didTapScanQR.asObservable().subscribe(onNext: { [weak self] (_) in
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          if granted {} else {
            self?.openAppSettingsSubject.onNext(())
          }
        }
      case .denied:
        self?.openAppSettingsSubject.onNext(())
        return

      case .restricted:
        self?.openAppSettingsSubject.onNext(())
        return

      default:
        return
      }
    }).disposed(by: disposeBag)

    dependency.balanceService.updateDelegated()

    //When tap on balance - change balance type
    didTapBalance.withLatestFrom(Observable.combineLatest(self.dependency.balanceService.balances(), self.changedBalanceTypeSubject.asObservable()))
      .do(onNext: { [weak self] (val) in
      var newBalance: BalanceType
      switch val.1 {
      case .totalBalanceUSD:
        newBalance = .balanceBIP
      case .balanceBIP:
        newBalance = .totalBalanceBIP
      case .totalBalanceBIP:
        newBalance = .totalBalanceUSD
      }
      self?.dependency.appSettingsSerivce.balanceType = newBalance.rawValue
      self?.changedBalanceTypeSubject.onNext(newBalance)
      let text = self?.balanceHeaderText(balanceType: newBalance, balances: val.0)
      self?.availableBalance.onNext(text?.1 ?? NSAttributedString())
    }).subscribe().disposed(by: disposeBag)

    reachability?.rx.isDisconnected.map({ _ -> String in
      return "Network is not reachable".localized()
    })
    .subscribe(self.showErrorMessage)
    .disposed(by: disposeBag)

    didScanQR.asObservable()
      .subscribe(onNext: { [weak self] (val) in
        guard let `self` = self else { return }
        let url = URL(string: val ?? "")
        if true == val?.isValidAddress() {
          return
        } else if true == val?.isValidPublicKey() {
          return
        } else if let url = url, let rawViewController = RawTransactionRouter.rawTransactionViewController(with: url,
                                                                                                           balanceService: self.dependency.balanceService,
                                                                                                           coinService: self.dependency.coinService) {
          return
        }
        self.showErrorMessage.onNext("Invalid transaction data".localized())
      }).disposed(by: disposeBag)

    //Stories
    Observable.of(dependency.storiesService.stories().map {_ in}, forceUpdateStories, self.dependency.appSettings.showStoriesObservable.map {_ in}).merge()
      .filter { self.dependency.appSettings.showStories }
      .withLatestFrom(dependency.storiesService.stories())
      .map({ (strs) -> [BaseTableSectionItem] in
        var section = BaseTableSectionItem(identifier: "Stories")
        section.items = strs.sorted(by: { (story1, story2) -> Bool in
          let story1Seen = !self.dependency.storiesService.hasSeen(storyId: story1.internalIdentifier)
          let story2Seen = !self.dependency.storiesService.hasSeen(storyId: story2.internalIdentifier)
          return story1Seen && !story2Seen
        }).map({ (story) -> StoryCollectionViewCellItem in
          let seenKey = String(self.dependency.storiesService.hasSeen(storyId: story.internalIdentifier))

          let item = StoryCollectionViewCellItem(reuseIdentifier: "StoryCollectionViewCell",
                                                 identifier: "StoryCollectionViewCell_\(story.internalIdentifier)_\(seenKey)")
          item.backgroundImageURL = story.icon
          item.isNew = !self.dependency.storiesService.hasSeen(storyId: story.internalIdentifier)
          item.title = story.title
          return item
        })
        return [section]
    }).subscribe(storiesSubject).disposed(by: disposeBag)

    self.dependency.appSettings.showStoriesObservable.filter { (showStories) -> Bool in
      return !(showStories ?? true)
    }.map({ _ -> [BaseTableSectionItem] in
      return []
    }).subscribe(storiesSubject).disposed(by: disposeBag)

    dependency.storiesService.updateStories()
  }

  func balanceHeaderText(balanceType: BalanceType, balances: BalanceService.BalancesResponse) -> BalanceHeaderItem {
    let balance = balances.baseCoinBalance
    let usdBalance = balances.totalUSDBalance
    let totalBalance = balances.totalMainCoinBalance

    var resultBalance: Decimal

    switch balanceType {
    case .totalBalanceUSD:
      resultBalance = usdBalance
    case .balanceBIP:
      resultBalance = balance
    case .totalBalanceBIP:
      resultBalance = totalBalance
    }

    return self.balanceHeaderItem(balanceType: balanceType,
                                       balance: resultBalance,
                                       isUSD: balanceType == .totalBalanceUSD)
  }

  // MARK: -

  var balanceService: BalanceService! {
    return self.dependency.balanceService
  }

  func showWalletObservable() -> Observable<Void> {
    return didTapSelectWallet.map { $0 }
  }

  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

  private func balanceHeaderItem(
    balanceType: BalanceType,
    balance: Decimal,
    isUSD: Bool) -> BalanceHeaderItem {
    var text: NSAttributedString?
    var title: String?

    switch balanceType {
    case .balanceBIP:
      title = "Available Balance".localized()
    case .totalBalanceBIP:
      title = "Total Balance".localized()
    case .totalBalanceUSD:
      title = "Total Balance".localized()
    }
    text = headerViewTitleText(with: balance, isUSD: isUSD)
    return BalanceHeaderItem(title: title, text: text, animated: false)
  }

  func headerViewLastUpdatedTitleText(balanceType: BalanceType, seconds: TimeInterval?) -> String {
    let balanceTypeStr = balanceType == .balanceBIP ? "Available Balance" : "Total Balance"
    guard let seconds = seconds else { return balanceTypeStr }
    var string = "\(balanceTypeStr) (Updated ".localized()
    var dateText = "\(Int(seconds)) sec"
    if seconds < 5 {
      dateText = "just now)".localized()
    } else if seconds > 60 * 60 {
      dateText = "more than an hour ago)".localized()
    } else if seconds > 60 {
      dateText = "more than a minute ago)".localized()
    }
    string.append(dateText)
    if seconds >= 5 {
      string.append(" ago)")
    }
    return string
  }

  private func headerViewTitleText(with balance: Decimal, isUSD: Bool = false) -> NSAttributedString {
    let formatter = isUSD ? CurrencyNumberFormatter.USDFormatter : coinFormatter
    let balanceString = Array((formatter.string(from: balance as NSNumber) ?? "").split(separator: "."))

    let string = NSMutableAttributedString()
    if isUSD {
      string.append(NSAttributedString(string: "$",
                                       attributes: [.foregroundColor: UIColor.white,
                                                    .kern: 0.4,
                                                    .font: UIFont.semiBoldFont(of: 30.0)]))
    }
    string.append(NSAttributedString(string: String(balanceString[0]),
                                     attributes: [.foregroundColor: UIColor.white,
                                                  .kern: 0.4,
                                                  .font: UIFont.semiBoldFont(of: 30.0)]))
    string.append(NSAttributedString(string: ".",
                                     attributes: [.foregroundColor: UIColor.white,
                                                  .kern: 0.21,
                                                  .font: UIFont.semiBoldFont(of: 16.0)]))

    string.append(NSAttributedString(string: String(balanceString[1]),
                                     attributes: [.foregroundColor: UIColor.white,
                                                  .kern: 0.21,
                                                  .font: UIFont.semiBoldFont(of: 16.0)]))
    if !isUSD {
      string.append(NSAttributedString(string: " " + Coin.baseCoin().symbol!,
                                       attributes: [.foregroundColor: UIColor.white,
                                                    .kern: 0.21,
                                                    .font: UIFont.semiBoldFont(of: 16.0)]))
    }
    return string
  }

}
