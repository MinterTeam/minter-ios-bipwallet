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

class BalanceViewModel: BaseViewModel, ViewModel, WalletSelectableViewModel {

  typealias BalanceHeaderItem = (title: String?, text: NSAttributedString?, animated: Bool)

  enum BalanceType: String {
    case balanceBIP
    case totalBalanceBIP
    case totalBalanceUSD
  }

  var changedBalanceTypeSubject = BehaviorSubject<BalanceType>(value: BalanceType.balanceBIP)

  // MARK: -

  private let needsToUpdateBalance = PublishSubject<Void>()
  private let availableBalance = PublishSubject<NSAttributedString>()
  private let delegatedBalance = PublishSubject<String>()
  private let didTapSelectWallet = PublishSubject<Void>()
  private let didTapDelegatedBalance = PublishSubject<Void>()
  private let wallet = PublishSubject<String>()
  private let didTapBalance = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let didScanQR = PublishSubject<String?>()
  lazy var balanceTitleObservable = Observable.of(Observable<Int>.timer(0, period: 0.5, scheduler: MainScheduler.instance).map {_ in}, self.changedBalanceTypeSubject.map {_ in}).merge()

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
  }

  struct Output {
    var availabaleBalance: Observable<NSAttributedString>
    var delegatedBalance: Observable<String>
    var didTapSelectWallet: Observable<Void>
    var wallet: Observable<String?>
    var showDelegated: Observable<Void>
    var balanceTitle: Observable<String?>
    var didTapShare: Observable<Void>
    var didScanQR: Observable<String?>
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency

    self.input = Input(needsToUpdateBalance: needsToUpdateBalance.asObserver(),
                       didTapSelectWallet: didTapSelectWallet.asObserver(),
                       didTapDelegatedBalance: didTapDelegatedBalance.asObserver(),
                       didTapBalance: didTapBalance.asObserver(),
                       didTapShare: didTapShare.asObserver(),
                       didScanQR: didScanQR.asObserver()
    )

    self.output = Output(availabaleBalance: availableBalance.asObservable(),
                         delegatedBalance: delegatedBalance.asObservable(),
                         didTapSelectWallet: didTapSelectWallet.map { $0 },
                         wallet: walletObservable(),
                         showDelegated: didTapDelegatedBalance.asObservable(),
                         balanceTitle: balanceTitleObservable.withLatestFrom(Observable.combineLatest(balanceService.lastBlockAgo(), changedBalanceTypeSubject)).map { lastBlockAgo, balanceType -> String in
                          let ago = Date().timeIntervalSince1970 - (lastBlockAgo ?? 0)
                          return self.headerViewLastUpdatedTitleText(balanceType: balanceType, seconds: ago)
                         },
                         didTapShare: didTapShare.asObservable(),
                         didScanQR: didScanQR.asObservable()
    )

    bind()
  }

  // MARK: -

  func bind() {
    dependency.balanceService.balances().subscribe(onNext: { [weak self] (val) in
      let headerItem = self?.headerViewTitleText(with: val.baseCoinBalance) ?? NSAttributedString()
      self?.availableBalance.onNext(headerItem)
    }).disposed(by: disposeBag)

    dependency.balanceService.delegatedBalance().subscribe(onNext: { (val) in
      var str = CurrencyNumberFormatter.formattedDecimal(with: val.1 ?? 0.0, formatter: CurrencyNumberFormatter.coinFormatter)
      str += ""
      str += Coin.baseCoin().symbol!
      self.delegatedBalance.onNext(str)
    }).disposed(by: disposeBag)

    dependency.balanceService.updateDelegated()

    let balanceHeaderText = Observable.combineLatest(self.dependency.balanceService.balances(), self.changedBalanceTypeSubject.asObservable())
      .map({ (val) -> (BalanceType, NSAttributedString?) in
        let balance = val.0.baseCoinBalance
        let usdBalance = val.0.totalUSDBalance
        let totalBalance = val.0.totalMainCoinBalance
        let balanceType = val.1

        var newBalanceType: BalanceType
        var resultBalance: Decimal

        switch balanceType {
        case .totalBalanceUSD:
          newBalanceType = .balanceBIP
          resultBalance = balance
        case .balanceBIP:
          newBalanceType = .totalBalanceBIP
          resultBalance = totalBalance
        case .totalBalanceBIP:
          newBalanceType = .totalBalanceUSD
          resultBalance = usdBalance
        }

//        self?.changedBalanceTypeSubject.onNext(newBalanceType)
//        AppSettingsManager.shared.balanceType = newBalanceType.rawValue
//        AppSettingsManager.shared.save()
        let headerItem = self.balanceHeaderItem(balanceType: newBalanceType,
                                           balance: resultBalance,
                                           isUSD: newBalanceType == .totalBalanceUSD)
        return (newBalanceType, headerItem.text)
      })

    didTapBalance.skip(1)
      .withLatestFrom(balanceHeaderText).subscribe(onNext: { [weak self] val in
        self?.changedBalanceTypeSubject.onNext(val.0)
        self?.availableBalance.onNext(val.1 ?? NSAttributedString())
      }).disposed(by: disposeBag)
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

  func headerViewLastUpdatedTitleText(balanceType: BalanceType, seconds: TimeInterval) -> String {
    let balanceTypeStr = balanceType == .balanceBIP ? "Available Balance" : "Total Balance"
    var string = "\(balanceTypeStr) (Updated ".localized()
    var dateText = "\(Int(seconds)) sec"
    if seconds < 5 {
      dateText = "just now".localized()
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
