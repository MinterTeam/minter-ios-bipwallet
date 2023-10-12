import Foundation
import MinterCore
import MinterExplorer
import RxSwift

enum PoolServiceRouteType: String {
  case input
  case output
}

protocol PoolService {
  func route(from: String, to: String, amount: Decimal, type: PoolServiceRouteType) -> Observable<PoolManagerRouteResponse?>
}

enum ExplorerPoolServiceError: Error {
  case invalidResponse
}

class ExplorerPoolService: PoolService {

  private let manager = PoolManager(httpClient: APIClient())

  func route(from: String, to: String, amount: Decimal, type: PoolServiceRouteType = .input) -> Observable<PoolManagerRouteResponse?> {
    return Observable.create { (observer) -> Disposable in
      self.manager.route(coinFrom: from, coinTo: to, amount: amount, type: type.rawValue) { res, error in
        if error != nil {
          observer.onError(error!)
        } else {
          observer.onNext(res)
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

}
