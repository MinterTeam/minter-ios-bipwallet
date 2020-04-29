//
//  ExplorerBalanceService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import RxSwift
import SwiftCentrifuge

class ExplorerBalanceService: BalanceService {

  private var channel: String
  private var client: CentrifugeClient?
  private var isConnected: Bool = false
  private var addressSubscription: CentrifugeSubscription?
  private var blockSubscription: CentrifugeSubscription?

  private let accountManager = AccountManager()

  init(address: String) {
    let adr = "Mx" + address.stripMinterHexPrefix()
    self.channel = adr
    try? self.changeAddress(adr)

    self.accountSubject.filter{$0 != nil}.subscribe(onNext: { [weak self] (item) in
      if let address = item?.address {
        self?.channel = "Mx" + address.stripMinterHexPrefix()
        self?.websocketConnect()
      }
    }).disposed(by: disposeBag)

    UIApplication.shared.rx.didOpenApp.withLatestFrom(self.accountSubject).subscribe(onNext: { [weak self] (item) in
      if let address = item?.address {
        self?.channel = "Mx" + address.stripMinterHexPrefix()
        self?.websocketConnect()
      }
    }).disposed(by: disposeBag)

    UIApplication.shared.rx.applicationWillResignActive.subscribe(onNext: { [weak self] (_) in
      self?.unsubscribeBlocksChange()
      self?.unsubscribeAccountBalanceChange()
      self?.websocketDisconnect()
    }).disposed(by: disposeBag)
  }

  private var balancesSubject = ReplaySubject<BalancesResponse>.create(bufferSize: 1)
  private var delegatedSubject = ReplaySubject<([AddressDelegation]?, Decimal?)>.create(bufferSize: 1)
  private var lastBlockDateSubject = ReplaySubject<TimeInterval?>.create(bufferSize: 1)

  var disposeBag = DisposeBag()

  var accountSubject = BehaviorSubject<AccountItem?>(value: nil)

  var account: Observable<AccountItem?> {
    return accountSubject.asObservable()
  }

  func changeAddress(_ address: String) throws {
    guard address.isValidAddress() else { throw BalanceServiceError.incorrectAddress }

    guard let account = accountManager.loadLocalAccounts()?.filter({ (item) -> Bool in
      return address.stripMinterHexPrefix() == item.address.stripMinterHexPrefix()
    }).first else {
      throw BalanceServiceError.incorrectAddress
    }
    self.accountSubject.onNext(account)
  }

  func lastBlockDate() -> Observable<TimeInterval?> {
    return lastBlockDateSubject.asObservable()
  }

  func balances() -> Observable<BalancesResponse> {
    return balancesSubject.asObservable()
  }

  func delegated() -> Observable<([AddressDelegation]?, Decimal?)> {
    return delegatedSubject.asObservable()
  }

  func updateBalance() {

    account.flatMapLatest { (account) -> Observable<Event<BalancesResponse>> in
      return self.balances(address: account!.address).materialize()
    }.subscribe(onNext: { event in
      switch event {
      case .completed:
        break
      case .error(let error):
        return
//        self.balancesSubject.onError(error)
      case .next(let val):
        self.balancesSubject.onNext(val)
      }
    }).disposed(by: disposeBag)
  }

  func delegatedBalance() -> Observable<([AddressDelegation]?, Decimal?)> {
    return delegatedSubject.asObservable()

//      .subscribe(onNext: { [weak self] (delegation, total) in
//        self?.allDelegatedBalance.onNext(delegation ?? [])
//        if total != nil {
//          self?.delegatedBalance.onNext(total ?? 0.0)
//        } else {
//          let delegated = delegation?.reduce(0) { $0 + ($1.bipValue ?? 0.0) }
//          self?.delegatedBalance.onNext(delegated ?? 0.0)
//        }
//      }).disposed(by: disposeBag)
  }

  func updateDelegated() {
    account.flatMapLatest { (account) -> Observable<([AddressDelegation]?, Decimal?)> in
      guard let address = account?.address, address.isValidAddress() else { return Observable.empty() }
      return self.addressManager.delegations(address: address)
    }.asDriver(onErrorJustReturn: (nil, nil))
    .drive(delegatedSubject)
    .disposed(by: disposeBag)
  }

  enum ExplorerBalanceServiceError: Error {
    case noAddress
  }

  let httpClient = APIClient()
  lazy var addressManager = ExplorerAddressManager(httpClient: httpClient)

  func delegations(address: String, page: Int) -> Observable<[MinterExplorer.AddressDelegation]> {
    return Observable.create { (observable) -> Disposable in
      self.addressManager.delegations(address: address, page: page) { delegations, total, error in

        guard error == nil else {
          observable.onError(error!)
          return
        }
        observable.onNext(delegations ?? [])
        observable.onCompleted()
      }
      return Disposables.create()
    }
  }

  func balances(address: String) -> Observable<BalancesResponse> {
    return Observable.create { (observer) -> Disposable in

      guard address.isValidAddress() else {
        observer.onError(ExplorerBalanceServiceError.noAddress)
        return Disposables.create()
      }

      self.addressManager.address(address: address, withSum: true) { (response, err) in

        var totalMainCoinBalance: Decimal = 0
        var totalUSDBalance: Decimal = 0
        var baseCoinBalance: Decimal = 0
        //Second decimal to be used for BIP equivalent
        var allBalances = [String: (Decimal, Decimal)]()

        guard nil == err else {
          observer.onError(err!)
          return
        }

        let address = response ?? [:]
        guard let ads = (address["address"] as? String)?.stripMinterHexPrefix(),
          let coins = address["balances"] as? [[String: Any]] else {
            observer.onError(ExplorerBalanceServiceError.noAddress)
          return
        }

        if let totalBalanceBaseCoin = address["total_balance_sum"] as? String,
          let totalBalance = Decimal(string: totalBalanceBaseCoin) {
          totalMainCoinBalance = totalBalance
        }

        if let totalBalanceUSD = address["total_balance_sum_usd"] as? String,
          let totalBalance = Decimal(string: totalBalanceUSD) {
          totalUSDBalance = totalBalance
        }

        baseCoinBalance = coins.filter({ (dict) -> Bool in
          return ((dict["coin"] as? String) ?? "").uppercased() == Coin.baseCoin().symbol!.uppercased()
        }).map({ (dict) -> Decimal in
          return Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
        }).reduce(0, +)

        if let defaultCoin = Coin.baseCoin().symbol {
          allBalances[defaultCoin] = (0.0, 0.0)
        }
        coins.forEach({ (dict) in
          if let key = dict["coin"] as? String {
            let amnt = Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
            allBalances[key.uppercased()] = (amnt, 0.0)
          }
        })

        let resp = BalancesResponse(totalMainCoinBalance, totalUSDBalance, baseCoinBalance, allBalances)
        observer.onNext(resp)
        observer.onCompleted()
      }

      return Disposables.create()
    }
  }

}

class ExplorerTransactionService: TransactionService {

  let explorerManager = ExplorerTransactionManager(httpClient: APIClient())

  func transactions(address: String, filter: TransactionServiceFilter?, page: Int) -> Observable<[MinterExplorer.Transaction]> {
    return Observable.create { (observable) -> Disposable in
      self.explorerManager.transactions(address: address, sendType: filter?.rawValue, page: page) { (transactions, error) in

        guard error == nil else {
          observable.onError(error!)
          return
        }

        observable.onNext(transactions ?? [])
        observable.onCompleted()
      }
      return Disposables.create()
    }
  }

}

extension ExplorerBalanceService: CentrifugeClientDelegate, CentrifugeSubscriptionDelegate {

  // MARK: -

  func websocketConnect() {
      let config = CentrifugeClientConfig()
      client = CentrifugeClient(url: MinterExplorerWebSocketURL!.absoluteURL.absoluteString + "?format=protobuf",
                                config: config,
                                delegate: self)
    self.client?.connect()
  }

  func websocketDisconnect() {
    self.client?.disconnect()
  }

  private func subscribeAccountBalanceChange() {
    guard self.isConnected == true else {
      return
    }

    do {
      addressSubscription = try client?.newSubscription(channel: self.channel, delegate: self)
      addressSubscription?.subscribe()
    } catch {
      print("Can not create subscription: \(error)")
    }
  }

  private func subscribeBlocksChange() {
    guard self.isConnected == true else {
      return
    }

    do {
      blockSubscription = try client?.newSubscription(channel: "blocks", delegate: self)
      blockSubscription?.subscribe()
    } catch {
      print("Can not create subscription: \(error)")
    }
  }

  private func unsubscribeAccountBalanceChange() {
    addressSubscription?.unsubscribe()
  }

  private func unsubscribeBlocksChange() {
    blockSubscription?.unsubscribe()
  }

  func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
    self.isConnected = true
    subscribeAccountBalanceChange()
    subscribeBlocksChange()
  }

  func onDisconnect(_ client: CentrifugeClient, _ event: CentrifugeDisconnectEvent) {
    self.isConnected = false
  }

  func onPublish(_ subscription: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
    if subscription.channel == "blocks" {
      guard let json = try? JSONSerialization.jsonObject(with: event.data, options: []) as? [String: Any] else { return }
      if let timestamp = json["timestamp"] as? String {
        let dateFormatter = ISO8601DateFormatter()
        let blockTimestamp = dateFormatter.date(from: timestamp)?.timeIntervalSince1970
        if let blockTimestamp = blockTimestamp {
          self.lastBlockDateSubject.onNext(blockTimestamp)
        }
      }
    } else {
      DispatchQueue.main.async {
        self.updateBalance()
        self.updateDelegated()
      }
    }
  }
}
