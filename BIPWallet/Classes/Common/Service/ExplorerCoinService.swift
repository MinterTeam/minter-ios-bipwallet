import Foundation
import RxSwift
import MinterCore
import MinterExplorer

class ExplorerCoinService: CoinService {

  init() {
    loadCoins()
  }

  private let manager = ExplorerCoinManager(httpClient: APIClient(headers: ["X-Minter-Chain-Id": XMinterChainId]))

  private var allCoins = [Coin]()

  private let disposeBag = DisposeBag()

  func updateCoins() {
    loadCoins()
  }

  func updateCoinsWithResponse() -> Observable<Bool> {
    manager.coins(term: "").map { (coins) -> [Coin] in
      return coins ?? []
    }.do(onNext: { [weak self] (coins) in
      self?.setCoins(coins)
    }).map({ (coins) -> Bool in
      return coins.count > 0
    })
  }

  private func loadCoins() {
    Observable.zip(manager.verifiedCoins().catchErrorJustReturn([]), manager.coins(term: "")).map { (result) -> [Coin] in
      let coins = result.1
      let verified = result.0
      return (coins ?? []).map { coin in
        var newCoin = coin
        newCoin.isOracleVerified = verified?.contains(where: { ver in
          coin.id == ver.id
        }) ?? false
        return newCoin
      }
    }.filter({ (coins) -> Bool in
      return coins.count > 0
    }).subscribe(onNext: { (coins) in
      self.setCoins(coins)
    }).disposed(by: disposeBag)
  }

  private func setCoins(_ coins: [Coin]) {
    self.allCoins = coins.map({ (coin) -> Coin in
      if coin.id == Coin.baseCoin().id! {
        coin.reserveBalance = Decimal.greatestFiniteMagnitude
      }
      return coin
    })
  }

  func coins(by term: String) -> Observable<[Coin]> {
    return Observable.create { (observer) -> Disposable in
      let term = term.lowercased()
      let coins = self.allCoins.filter { (con) -> Bool in
        return (con.symbol ?? "").lowercased().starts(with: term)
      }.sorted(by: { (coin1, coin2) -> Bool in
        if term == (coin1.symbol ?? "").lowercased() {
          return true
        } else if (coin2.symbol ?? "").lowercased() == term {
          return false
        }
        return (coin1.reserveBalance ?? 0) > (coin2.reserveBalance ?? 0)
      })
      observer.onNext(coins)
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func coins() -> Observable<[Coin]> {
    return manager.coins(term: "").map { (coins) -> [Coin] in
      return coins ?? []
    }.filter({ (coins) -> Bool in
      return coins.count > 0
    }).do { (coins) in
      self.setCoins(coins)
    }
  }

  func coinExists(name: String) -> Observable<Bool> {
    return Observable.create { (observer) -> Disposable in
      observer.onNext(self.allCoins.contains(where: { (coin) -> Bool in
        return (coin.symbol ?? "").lowercased() == name.lowercased()
      }))
      observer.onCompleted()
      return Disposables.create()
    }
  }

  func coinId(symbol: String) -> Int? {
    guard symbol != Coin.baseCoin().symbol! else {
      return Coin.baseCoin().id
    }

    let coins = self.allCoins.filter { (coin) -> Bool in
      return (coin.symbol ?? "").lowercased() == symbol.lowercased()
    }
    guard coins.count <= 1 else { return nil }

    return coins.first?.id
  }

  func coinBy(id: Int) -> Coin? {
    return allCoins.first { (coin) -> Bool in
      return coin.id == id
    }
  }

  func coinWith(predicate: (Coin) -> (Bool)) -> Coin? {
    return allCoins.first { (coin) -> Bool in
      return predicate(coin)
    }
  }

  func route(fromCoin: String, toCoin: String, amount: Decimal, type: String = "input") -> Observable<(Decimal, [Coin])> {
    return Observable.create { (observer) -> Disposable in
      self.manager.route(fromCoin: fromCoin, toCoin: toCoin, type: type, amount: amount) { estimate, coins, error in
        guard error == nil else {
          observer.onError(error!)
          return
        }
        observer.onNext((estimate ?? 0.0, coins ?? []))
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  public func estimate(fromCoin: String, toCoin: String, amount: Decimal, type: PoolServiceRouteType) -> Observable<CoinManagerEstimateResponse?> {
    return Observable.create { (observer) -> Disposable in
      self.manager.estimate(fromCoin: fromCoin, toCoin: toCoin, type: type.rawValue, amount: amount) { response, error in
        guard error == nil else {
          observer.onError(error!)
          return
        }
        observer.onNext(response)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

}

enum ExplorerCoinManagerRxError: Error {
  case noCoin
}

extension ExplorerCoinManager {

  func coin(by term: String) -> Observable<Coin?> {
    return Observable.create { (observer) -> Disposable in
      self.coins(term: term) { (coins, error) in

        guard error == nil else {
          observer.onError(error!)
          return
        }
        if let coin = coins?.filter({ (coin) -> Bool in
          return coin.symbol?.lowercased() == term.lowercased()
        }).first {
          observer.onNext(coin)
        } else {
          observer.onNext(nil)
        }
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func coins(term: String) -> Observable<[Coin]?> {
    return Observable.create { (observer) -> Disposable in
      self.coins(term: term) { (coins, error) in

        guard error == nil else {
          observer.onError(error!)
          return
        }

        observer.onNext(coins)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func verifiedCoins() -> Observable<[Coin]?> {
    return Observable.create { (observer) -> Disposable in
      self.verifiedCoins() { (coins, error) in

        guard error == nil else {
          observer.onError(error!)
          return
        }

        observer.onNext(coins)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

}
