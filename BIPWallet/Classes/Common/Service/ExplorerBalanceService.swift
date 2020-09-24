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

  private var channel: String?
  private var client: CentrifugeClient?
  private var isConnected: Bool = false
  private var addressSubscription: CentrifugeSubscription?
  private var blockSubscription: CentrifugeSubscription?
  var accountSubscription = [String: CentrifugeSubscription]()

  private let accountManager = AccountManager()

  init() {
    self.accountSubject.filter{$0 != nil}.subscribe(onNext: { [weak self] (item) in
      if !(self?.isConnected ?? true) {
        self?.websocketConnect()
      }
      if let address = item?.address {
        self?.channel = "Mx" + address.stripMinterHexPrefix()
        self?.subscribeAccountBalanceChange()
      }
    }).disposed(by: disposeBag)

    UIApplication.shared.rx.didOpenApp.withLatestFrom(self.accountSubject).subscribe(onNext: { [weak self] (item) in
      if let address = item?.address {
        self?.channel = "Mx" + address.stripMinterHexPrefix()
        self?.websocketConnect()
      }
      self?.updateBalance()
      self?.updateDelegated()
    }).disposed(by: disposeBag)

    UIApplication.shared.rx.applicationDidEnterBackground.subscribe(onNext: { [weak self] (_) in
      self?.unsubscribeBlocksChange()
      self?.unsubscribeAccountBalanceChange()
      self?.websocketDisconnect()
    }).disposed(by: disposeBag)

    forceUpdateBalance
      .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
      .withLatestFrom(account)
      .filter{ $0 != nil }.flatMapLatest ({ [weak self] (account) -> Observable<Event<BalancesResponse>> in
        guard let `self` = self else { return Observable.empty() }
        return self.balances(address: account!.address).materialize()
      }).subscribe(onNext: { event in
        switch event {
        case .completed:
          break
        case .error(_):
          return
        case .next(let val):
          self.balancesSubject.onNext(val)
        }
      }).disposed(by: disposeBag)

    forceUpdateDelegated
      .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
      .withLatestFrom(account)
      .flatMapLatest { (account) -> Observable<([AddressDelegation]?, Decimal?)> in
        guard let address = account?.address, address.isValidAddress() else { return Observable.empty() }
        return self.addressManager.delegations(address: address)
      }.withLatestFrom(account) {
        ($1?.address, $0.0, $0.1)
      }
      .asDriver(onErrorJustReturn: (nil, nil, nil))
      .drive(delegatedSubject)
      .disposed(by: disposeBag)
  }

  private let balancesSubject = ReplaySubject<BalancesResponse>.create(bufferSize: 1)
  private let delegatedSubject = ReplaySubject<(String?, [AddressDelegation]?, Decimal?)>.create(bufferSize: 1)
  private let lastBlockAgoSubject = ReplaySubject<TimeInterval?>.create(bufferSize: 1)
  private let forceUpdateBalance = PublishSubject<Void>()
  private let forceUpdateDelegated = PublishSubject<Void>()

  private let disposeBag = DisposeBag()

  private let accountSubject = BehaviorSubject<AccountItem?>(value: nil)

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
    account.lastSelected = Date()
    self.accountSubject.onNext(account)
  }

  func lastBlockAgo() -> Observable<TimeInterval?> {
    return lastBlockAgoSubject.asObservable()
  }

  func balances() -> Observable<BalancesResponse> {
    return balancesSubject.asObservable()
  }

  func delegated() -> Observable<(String?, [AddressDelegation]?, Decimal?)> {
    return delegatedSubject.asObservable()
  }

  func updateBalance() {
    forceUpdateBalance.onNext(())
  }

  func delegatedBalance() -> Observable<(String?, [AddressDelegation]?, Decimal?)> {
    return delegatedSubject.asObservable()
  }

  func updateDelegated() {
    forceUpdateDelegated.onNext(())
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

      self.addressManager.address(address: address, withSum: true) { (response) in
        var totalMainCoinBalance: Decimal = 0
        var totalUSDBalance: Decimal = 0
        var baseCoinBalance: Decimal = 0
        //Second decimal to be used for BIP equivalent
        var allBalances = [String: (Decimal, Decimal)]()

        var addr: ExplorerAddressManager.BalanceResponse?
        switch response {
        case .error(let error):
          observer.onError(error)
          return
        case .response(let balanceResponse):
          addr = balanceResponse
        }

        guard let ads = addr?.address.stripMinterHexPrefix(), let balances = addr?.balances else {
          observer.onError(ExplorerBalanceServiceError.noAddress)
          return
        }

        if let totalBalanceBaseCoin = addr?.totalBalanceSum {
          totalMainCoinBalance = totalBalanceBaseCoin
        }

        if let totalBalanceUSD = addr?.totalBalanceSumUSD {
          totalUSDBalance = totalBalanceUSD
        }

        //Total base coin amount
        baseCoinBalance = balances.first(where: { (val) -> Bool in
          val.coin.id == Coin.baseCoin().id!
        })?.amount ?? 0.0

        if let defaultCoin = Coin.baseCoin().symbol {
          allBalances[defaultCoin] = (0.0, 0.0)
        }

        balances.forEach { (val) in
          if let key = val.coin.symbol?.uppercased() {
            allBalances[key] = (val.amount, val.bipAmount)
          }
        }

        let resp = BalancesResponse(address: address, totalMainCoinBalance, totalUSDBalance, baseCoinBalance, allBalances)
        observer.onNext(resp)
        observer.onCompleted()
      }

      return Disposables.create()
    }
  }

  func balances(addresses: [String]) -> Observable<[String: BalancesResponse]> {
    return Observable.create { (observer) -> Disposable in
      return Disposables.create()
    }
  }

}

class ExplorerTransactionService: TransactionService {

  func transaction(hash: String) -> Observable<MinterExplorer.Transaction?> {
    return Observable.create { (observable) -> Disposable in
      self.explorerManager.transaction(hash: hash) { transaction, error in

        guard error == nil else {
          observable.onError(TransactionServiceError.custom(error: error!))
          return
        }

        observable.onNext(transaction)
        observable.onCompleted()
      }
      return Disposables.create()
    }
  }

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
    guard !self.isConnected else { return }
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
    guard self.isConnected == true, let channel = self.channel else {
      return
    }

    do {
      let subs = try client?.newSubscription(channel: channel, delegate: self)
      subs?.subscribe()
      accountSubscription[channel] = subs

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
//    addressSubscription?.unsubscribe()
    guard let channel = self.channel else { return }
    accountSubscription[channel]?.unsubscribe()
    accountSubscription[channel] = nil
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
          self.lastBlockAgoSubject.onNext(blockTimestamp)
        }
      }
    } else {
      DispatchQueue.main.async {
        self.updateBalance()
        self.updateDelegated()
      }
    }
  }

  func onJoin(_ sub: CentrifugeSubscription, _ event: CentrifugeJoinEvent) {
//    print(event)
  }

  func onLeave(_ sub: CentrifugeSubscription, _ event: CentrifugeLeaveEvent) {
//    print(event)
  }

}
