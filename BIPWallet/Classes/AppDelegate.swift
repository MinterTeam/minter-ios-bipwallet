//
//  AppDelegate.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift
import RxRouting
import MinterCore
import MinterExplorer
import MinterMy

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var disposeBag = DisposeBag()
  let isTestnet = true//(Bundle.main.infoDictionary?["CFBundleName"] as? String)?.contains("Testnet") ?? false

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let isUITesting = ProcessInfo.processInfo.arguments.contains("UITesting")

    let conf = Configuration()
    if isUITesting {
      MinterGateBaseURLString = "https://qa.gate-api.minter.network"
    } else {
      if !isTestnet {
        MinterGateBaseURLString = "https://gate.apps.minter.network"
      } else {
        MinterGateBaseURLString = "https://gate-api.testnet.minter.network"
      }
    }

    MinterCoreSDK.initialize(urlString: conf.environment.nodeBaseURL, network: isTestnet ? .testnet : .mainnet)
    MinterExplorerSDK.initialize(APIURLString: isUITesting ? conf.environment.testExplorerAPIBaseURL : conf.environment.explorerAPIBaseURL,
                                 WEBURLString: conf.environment.explorerWebURL,
                                 websocketURLString: conf.environment.explorerWebsocketURL)
    MinterMySDK.initialize(network: isTestnet ? .testnet : .mainnet)

    window = UIWindow()

    let pinService = SecureStoragePINService()
    let authService = LocalStorageAuthService(storage: SecureStorage(namespace: "Auth"),
                                              accountManager: AccountManager(),
                                              pinService: pinService
    )

    let appCoordinator = AppCoordinator(window: window!,
                                        authService: authService,
                                        pinService: pinService)
    appCoordinator.start()
        .subscribe()
        .disposed(by: disposeBag)

    UIApplication.shared.rx.didOpenApp.skip(1)
      .filter({ (_) -> Bool in
        return !pinService.isUnlocked()
      })
      .flatMap { (state) -> Observable<Void> in
        return appCoordinator.start()
      }.subscribe().disposed(by: disposeBag)

    RxRouting.instance
    .register("minter://tx/<transaction>")
    .subscribe(onNext: { result in
      print(result)
      if let vc = RawTransactionRouter.rawTransactionViewController(with: result.url) {
        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
      }
    }).disposed(by: disposeBag)

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

}

extension AppDelegate {

  func appearance() {
      UINavigationBar.appearance().shadowImage = UIImage()
//    UINavigationBar.appearance().shadowImage = UIImage(named: "NavigationBarShadowImage")
//    UINavigationBar.appearance().tintColor = .white
//    UINavigationBar.appearance().barTintColor = UIColor.mainColor()
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

//    UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)

    let img = UIImage(named: "BackButtonIcon")?
      .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
      .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0))
    img?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 20)
    UINavigationBar.appearance().backIndicatorTransitionMaskImage = img
    UINavigationBar.appearance().backIndicatorImage = img
    UINavigationBar.appearance().isTranslucent = false

    UITabBarItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.foregroundColor: UIColor.mainPurpleColor(),
      NSAttributedString.Key.font : UIFont.mediumFont(of: 11.0)
    ], for: .normal)
    UITabBarItem.appearance().setTitleTextAttributes([
      NSAttributedString.Key.foregroundColor : UIColor.mainColor(),
      NSAttributedString.Key.font : UIFont.mediumFont(of: 11.0)
    ], for: .selected)
  }

}
