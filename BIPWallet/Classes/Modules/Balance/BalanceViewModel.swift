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

class BalanceViewModel: BaseViewModel, ViewModel {

  // MARK: -

  private var needsToUpdateBalance = PublishSubject<Void>()
  private var availabaleBalance = PublishSubject<NSAttributedString>()
  private var delegatedBalance = PublishSubject<String>()
  private var didTapSelectWallet = PublishSubject<Void>()

  // MARK: - ViewModel

  var input: BalanceViewModel.Input!
  var output: BalanceViewModel.Output!
  var dependency: BalanceViewModel.Dependency!

  struct Input {
    var needsToUpdateBalance: AnyObserver<Void>
    var didTapSelectWallet: AnyObserver<Void>
  }

  struct Output {
    var availabaleBalance: Observable<NSAttributedString>
    var delegatedBalance: Observable<String>
    var didTapSelectWallet: Observable<Void>
  }

  struct Dependency {
    var balanceService: BalanceService
  }

  init(dependency: Dependency) {
    self.input = Input(needsToUpdateBalance: needsToUpdateBalance.asObserver(),
                       didTapSelectWallet: didTapSelectWallet.asObserver())
    self.output = Output(availabaleBalance: availabaleBalance.asObservable(),
                         delegatedBalance: delegatedBalance.asObservable(),
                         didTapSelectWallet: didTapSelectWallet.map { $0 })
    self.dependency = dependency

    super.init()

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

    didTapSelectWallet.subscribe(onNext: { _ in
      
      }).disposed(by: disposeBag)
  }

  private let coinFormatter = CurrencyNumberFormatter.coinFormatter

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
