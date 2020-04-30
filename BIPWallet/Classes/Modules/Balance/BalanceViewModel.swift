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

  var changedBalanceTypeSubject =
    BehaviorSubject<BalanceType>(value: BalanceType.balanceBIP)

  // MARK: -

  private let needsToUpdateBalance = PublishSubject<Void>()
  private let availabaleBalance = PublishSubject<NSAttributedString>()
  private let delegatedBalance = PublishSubject<String>()
  private let didTapSelectWallet = PublishSubject<Void>()
  private let didTapDelegatedBalance = PublishSubject<Void>()
  private let wallet = PublishSubject<String>()
  private let didTapBalance = PublishSubject<Void>()
  private let didTapShare = PublishSubject<Void>()
  private let didScanQR = PublishSubject<String?>()

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
//    var appSettings: AppSettings
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

    self.output = Output(availabaleBalance: availabaleBalance.asObservable(),
                         delegatedBalance: delegatedBalance.asObservable(),
                         didTapSelectWallet: didTapSelectWallet.map { $0 },
                         wallet: walletObservable(),
                         showDelegated: didTapDelegatedBalance.asObservable(),
                         balanceTitle: changedBalanceTypeSubject.map({ (type) -> String? in
                          switch type {
                          case .balanceBIP:
                            return "Available Balance"
                          default:
                            return "Total Balance"
                          }
                         }),
                         didTapShare: didTapShare.asObservable(),
                         didScanQR: didScanQR.asObservable()
    )

    bind()
  }

  // MARK: -

  func bind() {
    dependency.balanceService.balances().subscribe(onNext: { [weak self] (val) in
      let headerItem = self?.headerViewTitleText(with: val.baseCoinBalance) ?? NSAttributedString()
      self?.availabaleBalance.onNext(headerItem)
    }).disposed(by: disposeBag)

    dependency.balanceService.delegatedBalance().subscribe(onNext: { (val) in
      var str = CurrencyNumberFormatter.formattedDecimal(with: val.1 ?? 0.0, formatter: CurrencyNumberFormatter.coinFormatter)
      str += ""
      str += Coin.baseCoin().symbol!
      self.delegatedBalance.onNext(str)
    }).disposed(by: disposeBag)

    dependency.balanceService.updateDelegated()

    didTapBalance.skip(1)
      .withLatestFrom(Observable.combineLatest(self.dependency.balanceService.balances(), self.changedBalanceTypeSubject.asObservable()))
      .subscribe(onNext: { [weak self] (val) in
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

        self?.changedBalanceTypeSubject.onNext(newBalanceType)
//        AppSettingsManager.shared.balanceType = newBalanceType.rawValue
//        AppSettingsManager.shared.save()
        if let headerItem = self?.balanceHeaderItem(balanceType: newBalanceType,
                                           balance: resultBalance,
                                           isUSD: newBalanceType == .totalBalanceUSD) {
          self?.availabaleBalance.onNext(headerItem.text!)
        }
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
