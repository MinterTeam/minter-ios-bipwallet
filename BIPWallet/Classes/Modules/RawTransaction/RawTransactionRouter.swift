//
//  RawTransactionRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import BigInt
import RxSwift

class RawTransactionRouter {

	static var patterns: [String] {
		return ["tx", "tx/<string:d>"]
	}

  static let authService = LocalStorageAuthService(storage: SecureStorage(namespace: "Auth"),
                                                   accountManager: AccountManager(),
                                                   pinService: SecureStoragePINService()
  )

  static func viewController(path: [String], param: [String: Any],
                             balanceService: BalanceService,
                             coinService: CoinService) -> UIViewController? {
    var nonce: BigUInt?
    var gasPrice: BigUInt?
    var gasCoin: String = Coin.baseCoin().symbol!
    var type: RawTransactionType = .sendCoin
    var txData: Data?
    var payload: String?
    var userData: [String: Any]? = [:]

    guard let tx = param["d"] as? String else {
      return nil
    }
    var newTx = tx.data(using: .utf8) ?? Data()
    var rlpItem = RLP.decode(tx)
    if nil == rlpItem?[0]?.content,

      let data = Data(base64URLEncoded: tx) {
        newTx = data
        rlpItem = RLP.decode(data)
    }

    if
      let rlpItem = rlpItem,
      let content = rlpItem[0]?.content {

			switch content {
			case .noItem:
				return nil

			case .list(let items, _, _):
				if items.count >= 3 {//shortened version
					guard
						let typeData = items[safe: 0]?.data,
						let txDataData = RLP.decode(items[safe: 1]?.data ?? Data())?.data,
						let payloadData = items[safe: 2]?.data
					else { return nil }

					let nonceData = items[safe: 3]?.data ?? Data()
					let gasPriceData = items[safe: 4]?.data ?? Data()
					let gasCoinData = items[safe: 5]?.data ?? Data()

					let nonceValue = BigUInt(nonceData)
					nonce = nonceValue > 0 ? nonceValue : nil

					let gasPriceValue = BigUInt(gasPriceData)
					gasPrice = gasPriceValue > 0 ? gasPriceValue : nil
          let coinId: Int = gasCoinData.withUnsafeBytes { $0.pointee }
          if let newGasCoin = coinService.coinBy(id: coinId)?.symbol {
            gasCoin = (newGasCoin == "") ? Coin.baseCoin().symbol! : newGasCoin
            guard gasCoin.isValidCoin() else {
              return nil
            }
					}
					let typeBigInt = BigUInt(typeData)
					guard let txType = RawTransactionType.type(with: typeBigInt) else {
						return nil
					}
					type = txType
					txData = txDataData
					payload = String(data: payloadData, encoding: .utf8)
				}

			case .data(let val):
				return nil
			}

			if let password = param["p"] as? String {
        if let decoded = Data(base64URLEncoded: password) {
          if let pwd = String(data: decoded, encoding: .utf8) {
            userData?["p"] = pwd
          } else {
            if let decodedPassword = RLP.decode(password),
              let passwordData = decodedPassword[0]?.data,
              let passwordString = String(data: passwordData, encoding: .utf8) {
              userData?["p"] = passwordString
            }
          }
        }
			}

      return viewController(nonce: nonce,
                            gasPrice: gasPrice,
                            gasCoin: gasCoin,
                            type: type,
                            data: txData,
                            payload: payload,
                            serviceData: nil,
                            signatureType: nil,
                            userData: userData,
                            balanceService: balanceService,
                            coinService: coinService)
    }
		return nil
	}

  static func rawTransactionViewController(with url: URL, balanceService: BalanceService, coinService: CoinService) -> UIViewController? {
    // new format
    if url.params()["d"] == nil {
      let txData = String(url.path.split(separator: "/").last ?? "")
      var params = url.params()
      params["d"] = txData
      guard let viewController = RawTransactionRouter.viewController(path: ["tx"], param: params, balanceService: balanceService, coinService: coinService) else { return nil }
      return UINavigationController(rootViewController: viewController)
    }
		return nil
	}

  static func viewController(// swiftlint:disable:this type_body_length cyclomatic_complexity function_parameter_count
    nonce: BigUInt?,
    gasPrice: BigUInt?,
    gasCoin: String?,
    type: RawTransactionType,
    data: Data?,
    payload: String?,
    serviceData: Data?,
    signatureType: Data?,
    userData: [String: Any]?,
    balanceService: BalanceService,
    coinService: CoinService
  ) -> UIViewController? {

    let viewModel: RawTransactionViewModel
    do {
      let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
                                                          gate: GateManager.shared,
                                                          authService: self.authService, 
                                                          balanceService: balanceService,
                                                          coinService: coinService)
      viewModel = try RawTransactionViewModel(
        dependency: dependency,
        nonce: nonce,
        gasPrice: gasPrice,
        gasCoin: gasCoin,
        type: type,
        data: data,
        payload: payload,
        serviceData: nil,
        signatureType: nil,
        userData: userData)
    } catch {
      return nil
    }

    let viewController = RawTransactionViewController.initFromStoryboard(name: "RawTransaction")
    viewController.viewModel = viewModel
    return viewController
  }

}

class RawTransactionCoordinator: BaseCoordinator<Void> {

  let rootViewController: UIViewController
  let url: URL
  let balanceService: BalanceService
  let transactionService: TransactionService
  let coinService: CoinService

  init(rootViewController: UIViewController, url: URL,
       balanceService: BalanceService,
       transactionService: TransactionService,
       coinService: CoinService) {
    self.rootViewController = rootViewController
    self.url = url
    self.balanceService = balanceService
    self.transactionService = transactionService
    self.coinService = coinService
  }

  override func start() -> Observable<Void> {
    guard let controller = RawTransactionRouter.rawTransactionViewController(with: url,
                                                                             balanceService: balanceService,
                                                                             coinService: coinService) as? UINavigationController else {
      return Observable.empty()
    }

    let rawTransactionViewController = controller.viewControllers.first as? RawTransactionViewController

    rawTransactionViewController?.viewModel.output.showExchange.flatMap({ val -> Observable<Void> in
      guard val != nil else { return Observable.empty() }
      return self.showExchange(controller: controller, coin: val?.0, amount: val?.1, neededAmount: val?.2)
    }).subscribe().disposed(by: disposeBag)

    rootViewController.present(controller, animated: true, completion: nil)

    return controller.rx.deallocated
  }

  func showExchange(controller: UIViewController, coin: String?, amount: Decimal?, neededAmount: Decimal?) -> Observable<Void> {
    let settings = ExchangeCoordinator.Settings(showBuy: true,
                                                buyCoin: coin,
                                                buyAmount: amount,
                                                neededAmount: neededAmount,
                                                closeAfterTransaction: true)

    let coordinator = ExchangeCoordinator(rootController: controller,
                                          balanceService: balanceService,
                                          transactionService: transactionService,
                                          coinService: ExplorerCoinService(),
                                          settings: settings)
    return coordinate(to: coordinator)
  }

}
