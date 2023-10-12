//
//  GateManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import Alamofire
import MinterCore
import RxSwift
import ObjectMapper

var MinterGateBaseURLString = "https://gate.minter.network"
let XMinterChainId = "chilinet"

enum GateManagerError: Error {
    case wrongResponse
}

enum MinterGateAPIURL {

    case nonce(address: String)
    case minGasPrice
    case estimateTXComission
    case estimateCoinSell
    case estimateCoinSellAll
    case estimateCoinBuy
    case send
  case priceCommissions

    func url() -> URL {
        switch self {

        case .nonce(let address):
            return URL(string: MinterGateBaseURLString + "/api/v1/nonce/" + address)!

        case .estimateCoinBuy:
            return URL(string: MinterGateBaseURLString + "/api/v2/estimate_coin_buy")!

        case .estimateCoinSell:
            return URL(string: MinterGateBaseURLString + "/api/v2/estimate_coin_sell")!

        case .estimateCoinSellAll:
            return URL(string: MinterGateBaseURLString + "/api/v2/estimate/coin-sell-all")!

        case .estimateTXComission:
            return URL(string: MinterGateBaseURLString + "/api/v1/estimate/tx-commission")!

        case .minGasPrice:
            return URL(string: MinterGateBaseURLString + "/api/v1/min-gas")!

        case .send:
            return URL(string: MinterGateBaseURLString + "/api/v1/transaction/push")!

    case .priceCommissions:
      return URL(string: MinterGateBaseURLString + "/api/v2/price_commissions")!

        }
    }
}

public struct EstimateConvertResponse {
  public var amount: Decimal
  public var commission: Decimal
  public var swapForm: String
}

class GateManager: BaseManager {

    // MARK: -

  var lastComission: Commission?
  let commissionSubject = ReplaySubject<Commission>.create(bufferSize: 1)

  static let shared = GateManager(httpClient: APIClient(headers: ["X-Minter-Chain-Id": XMinterChainId]))

  private(set) var lastGas = MinterCore.RawTransactionDefaultGasPrice

    // MARK: -

    func minGasPrice(completion: ((Int?, Error?) -> ())?) {

        let url = MinterGateAPIURL.minGasPrice.url()

        self.httpClient.getRequest(url, parameters: nil) { (response, error) in
            if let resp = response.data as? [String: Any],
                let gas = resp["gas"] as? String,
                let gasInt = Int(gas) {
                completion?(gasInt, nil)
            } else {
                completion?(nil, GateManagerError.wrongResponse)
            }
        }
    }

    /// Method retreives transaction count
    ///
    /// - Parameters:
    ///   - address: "Mx" prefixed address (e.g. Mx184ac726059e43643e67290666f7b3195093f870)
    ///   - completion: method which will be called after request finished
    public func nonce(for address: String, completion: ((Decimal?, Error?) -> ())?) {

        let url = MinterGateAPIURL.nonce(address: "Mx" + address.stripMinterHexPrefix()).url()

        self.httpClient.getRequest(url, parameters: nil) { (response, error) in

            var count: Decimal?
            var err: Error?

            defer {
                completion?(count, err)
            }

            guard nil == error else {
                err = error
                return
            }

            if let data = response.data as? [String: Any],
                let cnt = data["nonce"] as? String {
                count = Decimal(string: cnt)
            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

    /// Method retreives estimate coin buy
    ///
    /// - Parameters:
    ///   - coinFrom: coin to sell (e.g. MNT)
    ///   - coinTo: coin to buy (e.g. BELTCOIN)
    ///        - value: value to calculate estimates for
    ///   - completion: method which will be called after request finished
    public func estimateCoinBuy(coinFrom: String,
                              coinTo: String,
                              value: Decimal,
                              completion: ((EstimateConvertResponse?, Error?) -> ())?) {

        let url = MinterGateAPIURL.estimateCoinBuy.url()

        self.httpClient.getRequest(url, parameters: ["coin_to_buy": coinTo,
                                                                                                 "coin_to_sell": coinFrom,
                                                                                                 "value_to_buy": value,
                                                 "swap_from": "optimal",]) { (response, error) in
      var res: EstimateConvertResponse?
      var err: Error?

            defer {
        completion?(res, err)
            }

            guard nil == error else {
                err = error
                return
            }

            if let data = response.data as? [String: String],
                let pay = data["will_pay"],
                let commission = data["commission"],
        let swap = data["swap_from"] {
        res = EstimateConvertResponse(amount: Decimal(string: pay) ?? 0.0,
                                      commission: Decimal(string: commission) ?? 0.0,
                                      swapForm: swap)
            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

    /// Method retreives estimate coin sell
    ///
    /// - Parameters:
    ///   - coinFrom: coin to sell (e.g. MNT)
    ///   - coinTo: coin to buy (e.g. BELTCOIN)
    ///        - value: value to calculate estimates for
    ///   - completion: method which will be called after request finished
    public func estimateCoinSell(coinFrom: String,
                                                             coinTo: String,
                                                             value: Decimal,
                                                             completion: ((EstimateConvertResponse?, Error?) -> ())?) {

        let url = MinterGateAPIURL.estimateCoinSell.url()

        self.httpClient.getRequest(url, parameters: ["coin_to_buy": coinTo,
                                                 "coin_to_sell": coinFrom,
                                                 "value_to_sell": value,
                                                 "swap_from": "optimal",
    ]) { (response, error) in
      var res: EstimateConvertResponse?
            var err: Error?

            defer {
                completion?(res, err)
            }

            guard nil == error else {
                err = error
                return
            }

            if let data = response.data as? [String: String],
                let get = data["will_get"],
                let commission = data["commission"],
        let swap = data["swap_from"] {

        res = EstimateConvertResponse(amount: Decimal(string: get) ?? 0.0,
                                      commission: Decimal(string: commission) ?? 0.0,
                                      swapForm: swap)

            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

    /// Method retreives estimate coin sell
    ///
    /// - Parameters:
    ///   - coinFrom: coin to sell (e.g. MNT)
    ///   - coinTo: coin to buy (e.g. BELTCOIN)
    ///        - value: value to calculate estimates for
    ///        - gasPrice: gas price
    ///   - completion: method which will be called after request finished
    public func estimateCoinSellAll(coinFrom: String,
                                                                    coinTo: String,
                                                                    value: Decimal,
                                                                    gasPrice: Int,
                                                                    completion: ((Decimal?, Decimal?, Error?) -> ())?) {

        let url = MinterGateAPIURL.estimateCoinSellAll.url()

        self.httpClient.getRequest(url,
                                                             parameters: ["coin_to_buy": coinTo,
                                                                                        "coin_to_sell": coinFrom,
                                                                                        "value_to_sell": value,
                                                                                        "gas_price": gasPrice]) { (response, error) in

            var willGet: Decimal?
            var com: Decimal?
            var err: Error?

            defer {
                completion?(willGet, com, err)
            }

            guard nil == error else {
                err = error
                return
            }

            if let data = response.data as? [String: String],
                let get = data["will_get"],
                let commission = data["commission"] {
                    willGet = Decimal(string: get)
                    com = Decimal(string: commission)
            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

    /// Method retreives estimate comission for raw transaction
    ///
    /// - Parameters:
    ///   - rawTx: encoded raw transaction
    ///   - completion: method which will be called after request finished
    func estimateTXCommission(for rawTx: String,
                                                        completion: ((Decimal?, Error?) -> ())?) {

        let url = MinterGateAPIURL.estimateTXComission.url()

        self.httpClient.getRequest(url, parameters: ["transaction": rawTx]) { (response, error) in

            var com: Decimal?
            var err: Error?

            defer {
                completion?(com, err)
            }

            guard nil == error else {
                err = error
                return
            }

            if let data = response.data as? [String: String], let commission = data["commission"] {
                com = Decimal(string: commission)
            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

    /// Method sends raw transaction to the Minter network
    ///
    /// - Parameters:
    ///   - rawTransaction: encoded transaction
    ///   - completion: method which will be called after request finished
  ///   -
  public func sendRawTransaction(rawTransaction: String, completion: ( ((hash: String?, height: Decimal?, error: Error?)) -> ())?) {

        let url = MinterGateAPIURL.send.url()

        self.httpClient.postRequest(url, parameters: ["transaction": rawTransaction]) { (response, error) in

            var tx: String?
      var block: Decimal?
            var err: Error?

            defer {
                completion?((hash: tx, height: block, error: err))
            }

            guard nil == error else {
                err = error
                return
            }

      if let resp = response.data as? [String: Any] {
        if let hash = resp["hash"] as? String {
          tx = "Mt" + hash.stripMinterHexPrefix().lowercased()
        }
        if let transaction = resp["transaction"] as? [String: Any] {
          if let blockVal = transaction["height"] as? String {
            block = Decimal(string: blockVal)
          }
        }
            } else {
                err = GateManagerError.wrongResponse
            }
        }
    }

}

enum GateManagerRxError : Error {
  case noGas
}

enum GateManagerErrorRx: Error {
  case noCount
  case noCommission
  case noTransaction
}

extension GateManager {

  func estimateComission(tx: String) -> Observable<Decimal> {
    return Observable.create { (observer) -> Disposable in
      self.estimateTXCommission(for: tx) { (commission, error) in

        guard let commission = commission, nil == error else {
          observer.onError(error ?? GateManagerErrorRx.noCommission)
          return
        }

        observer.onNext(commission)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func estimateCoinSell(coinFrom: String,
                        coinTo: String,
                        value: Decimal,
                        isAll: Bool = false) -> Observable<EstimateConvertResponse> {
    return Observable.create { (observer) -> Disposable in
      self.estimateCoinSell(coinFrom: coinFrom,
                            coinTo: coinTo,
                            value: value,
                            completion: { (res, error) in
          guard error == nil && res != nil else {
          observer.onError(error ?? GateManagerErrorRx.noCommission)
          return
        }

        observer.onNext(res!)
        observer.onCompleted()
      })
      return Disposables.create()
    }
  }
  
  func estimateCoinBuy(coinFrom: String,
                       coinTo: String,
                       value: Decimal) -> Observable<EstimateConvertResponse> {
    return Observable.create { (observer) -> Disposable in
      self.estimateCoinBuy(coinFrom: coinFrom,
                           coinTo: coinTo,
                           value: value,
                           completion: { (res, error) in
          guard error == nil && res != nil else {
          observer.onError(error ?? GateManagerErrorRx.noCommission)
          return
        }

        observer.onNext(res!)
        observer.onCompleted()
      })
      return Disposables.create()
    }
  }

  func nonce(address: String) -> Observable<Int> {
    return Observable.create { (observer) -> Disposable in
      self.nonce(for: address) { (count, error) in

        guard let count = count, nil == error else {
          observer.onError(error ?? GateManagerErrorRx.noCount)
          return
        }
        let int = NSDecimalNumber(decimal: count).intValue
        observer.onNext(int)
        observer.onCompleted()
      }
      return Disposables.create()
    }
  }

  func minGas() -> Observable<Int> {
    return Observable.create { (observer) -> Disposable in
      self.minGasPrice(completion: { (gas, error) in
        guard nil == error && gas != nil else {
          observer.onError(error!)
          return
        }
        self.lastGas = gas ?? MinterCore.RawTransactionDefaultGasPrice

        observer.onNext(gas!)
        observer.onCompleted()
      })
      return Disposables.create()
    }
  }

  func send(rawTx: String?) -> Observable<(String?, Decimal?)> {
    return Observable.create { observer -> Disposable in
      if rawTx != nil {
        self.sendRawTransaction(rawTransaction: rawTx!, completion: { (hash, block, error) in
          guard nil == error else {
            observer.onError(error!)
            return
          }
          observer.onNext((hash, block))
          observer.onCompleted()
        })
      } else {
        observer.onError(GateManagerErrorRx.noTransaction)
      }
      return Disposables.create()
    }
  }
  
  func priceCommissions() -> Observable<(Decimal?)> {
    return Observable.create { observer -> Disposable in
      let url = MinterGateAPIURL.priceCommissions.url()

      self.httpClient.getRequest(url, parameters: [:]) { (response, error) in
        guard let data = response.data as? [String: Any], error == nil else {
          observer.onError(error ?? GateManagerErrorRx.noCommission)
          return
        }
        
        let commissions = Mapper<Commission>().map(JSON: data)
        self.lastComission = commissions
        if commissions != nil {
          self.commissionSubject.onNext(commissions!)
        }
      }
      return Disposables.create()
    }
  }
}

struct Commission: Mappable {
  init?(map: Map) {
    self.mapping(map: map)
  }
  
  mutating func mapping(map: Map) {
    coin = Mapper<CoinMappable>().map(JSONObject: map.JSON["coin"])
    payloadByte <- map["payload_byte"]
    map.JSON.forEach({ val in
      if let commissionType = CommissionType(rawValue: val.key),
         let commissionValue = val.value as? String {
        transactionCommissions[commissionType] = Decimal(string: commissionValue)
      }
    })
  }
  
  var coin: Coin?
  
  var payloadByte: Decimal?
  var transactionCommissions: [CommissionType: Decimal] = [:]
  
  enum CommissionType: String {
    case send
    case buyBancor = "buy_bancor"
    case sellBancor = "sell_bankor"
    case sellAllBancor = "sell_all_bancor"
    case buyPoolBase = "buy_pool_base"
    case buyPoolDelta = "buy_pool_delta"
    case sellPoolBase = "sell_pool_base"
    case sellPoolDelta = "sell_pool_delta"
    case sellAllPoolBase = "sell_all_pool_base"
    case sellAllPoolDelta = "sell_all_pool_delta"
    case createTicker3 = "create_ticker3"
    case createTicker4 = "create_ticker4"
    case createTicker5 = "create_ticker5"
    case createTicker6 = "create_ticker6"
    case createTicker7_10 = "create_ticker7_10"
    case createCoin = "create_coin"
    case createToken = "create_token"
    case recreateCoin = "recreate_coin"
    case recreateToken = "recreate_token"
    case declareCandidacy = "declare_candidacy"
    case delegate
    case unbond
    case redeemCheck = "redeem_check"
    case setCandidateOn = "set_candidate_on"
    case setCandidateOff = "set_candidate_off"
    case createMultisig = "create_multisig"
    case multisendBase = "multisend_base"
    case multisendDelta = "multisend_delta"
    case editCandidate = "edit_candidate"
    case setHaltBlock = "set_halt_block"
    case editTickerOwner = "edit_ticker_owner"
    case editMultisig = "edit_multisig"
    case editCandidatePublicKey = "edit_candidate_public_key"
    case createSwapPool = "create_swap_pool"
    case addLiquidity = "add_liquidity"
    case removeLiquidity = "remove_liquidity"
    case editCandidateCommission = "edit_candidate_commission"
    case mintToken = "mint_token"
    case burnToken = "burn_token"
    case voteCommission = "vote_commission"
    case voteUpdate = "vote_update"
    
  }
}
