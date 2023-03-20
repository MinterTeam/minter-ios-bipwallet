//
//  AppDelegate.swift
//  BIPWallet
//x
//  Created by Alexey Sidorov on 07.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift
import RxRouting
import MinterCore
import MinterExplorer
import MinterMy
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var disposeBag = DisposeBag()
  let isTestnet = (Bundle.main.infoDictionary?["CFBundleName"] as? String)?.contains("Testnet") ?? false

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let isUITesting = ProcessInfo.processInfo.arguments.contains("UITesting")
    FirebaseApp.configure()

    let conf = Configuration()
    if isUITesting {
      MinterGateBaseURLString = "https://qa.gate-api.minter.network"
    } else {
      if !isTestnet {
        MinterGateBaseURLString = "https://gate-api.toronet.minter.network"
      } else {
        MinterGateBaseURLString = "https://gate-api.testnet.minter.network"
      }
    }

    MinterCoreSDK.initialize(urlString: conf.environment.nodeBaseURL, network: .testnet)
    MinterExplorerSDK.initialize(APIURLString: isUITesting ? conf.environment.testExplorerAPIBaseURL : conf.environment.explorerAPIBaseURL,
                                 WEBURLString: conf.environment.explorerWebURL,
                                 websocketURLString: conf.environment.explorerWebsocketURL)
    MinterMySDK.initialize(network: isTestnet ? .testnet : .mainnet)

    window = UIWindow()
    window?.makeKeyAndVisible()

    let pinService = SecureStoragePINService()
    let authService = LocalStorageAuthService(storage: SecureStorage(namespace: "Auth"),
                                              accountManager: AccountManager(),
                                              pinService: pinService
    )

    //If no accounts - remove PIN
    if authService.accounts().count == 0 && pinService.hasPIN() {
      pinService.removePIN()
    }

    let transactionService = ExplorerTransactionService()

    let appCoordinator = AppCoordinator(window: window!,
                                        authService: authService,
                                        pinService: pinService,
                                        transactionService: transactionService,
                                        coinService: ExplorerCoinService())

    appCoordinator.start().subscribe().disposed(by: disposeBag)

    Observable.of(UIApplication.shared.rx.didOpenApp.skip(1).map { _ -> RouteMatchResult? in
      return nil
    }, RxRouting.instance.register("mintertestnet://bip.to/tx/<transaction>").map { val -> RouteMatchResult? in
      return val
    }, RxRouting.instance.register("https://bip.to/tx/<transaction>").map { val -> RouteMatchResult? in
      return val
    }, RxRouting.instance.register("https://testnet.bip.to/tx/<transaction>").map { val -> RouteMatchResult? in
      return val
    }).merge().flatMap { (result) -> Observable<Event<Void>> in
      guard let url = result?.url else {

        if !pinService.isUnlocked() {
          return appCoordinator.start().materialize()
        }
        return Observable.empty().materialize()
      }
      return appCoordinator.start(with: url).materialize()
    }.subscribe().disposed(by: disposeBag)

    appearance()

    return true
  }

  func application(_ app: UIApplication,
                   open url: URL,
                   options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if RxRouting.instance.handle(url: url) {
      return true
    }
    return false
  }

  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
      if RxRouting.instance.handle(url: url) {
        return true
      }
    }
    return true
  }

}

extension AppDelegate {

  func appearance() {
    UINavigationBar.appearance().shadowImage = UIImage()
    UINavigationBar.appearance().titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.mainBlackColor(),
      NSAttributedString.Key.font: UIFont.semiBoldFont(of: 18.0)
    ]
    if #available(iOS 11.0, *) {
      UINavigationBar.appearance().setTitleVerticalPositionAdjustment(6, for: .default)
    }

    UIBarButtonItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.font: UIFont.defaultFont(of: 14),
      NSAttributedString.Key.foregroundColor: UIColor.white,
      NSAttributedString.Key.baselineOffset: 1
    ], for: .normal)

    UIBarButtonItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.font: UIFont.defaultFont(of: 14),
      NSAttributedString.Key.foregroundColor: UIColor.white,
      NSAttributedString.Key.baselineOffset: 1
    ], for: .highlighted)

    let img = UIImage(named: "BackButtonIcon")?
      .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
      .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0))
    img?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 20)
    UINavigationBar.appearance().backIndicatorTransitionMaskImage = img
    UINavigationBar.appearance().backIndicatorImage = img
    UINavigationBar.appearance().isTranslucent = false

    UITabBarItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.foregroundColor: UIColor.mainGreyColor(),
      NSAttributedString.Key.font : UIFont.mediumFont(of: 11.0)
    ], for: .normal)

    UITabBarItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.foregroundColor : UIColor.mainColor(),
      NSAttributedString.Key.font : UIFont.mediumFont(of: 11.0)
    ], for: .selected)
  }

}
