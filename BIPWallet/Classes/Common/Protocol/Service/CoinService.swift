import Foundation
import RxSwift
import MinterCore
import MinterExplorer

protocol CoinService: class {
      func updateCoins()
      func updateCoinsWithResponse() -> Observable<Bool>
      func coins() -> Observable<[Coin]>
      func coins(by term: String) -> Observable<[Coin]>
      func coinExists(name: String) -> Observable<Bool>
      func coinId(symbol: String) -> Int?
      func coinBy(id: Int) -> Coin?
      func coinWith(predicate: (Coin) -> (Bool)) -> Coin?
      func route(fromCoin: String, toCoin: String, amount: Decimal, type: String) -> Observable<(Decimal, [Coin])>
      func estimate(fromCoin: String, toCoin: String, amount: Decimal, type: PoolServiceRouteType) -> Observable<CoinManagerEstimateResponse?>
}
