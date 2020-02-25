//
//  AppDelegate.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift
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
        MinterGateBaseURLString = "https://texasnet.gate-api.minter.network"
      }
    }
    MinterCoreSDK.initialize(urlString: conf.environment.nodeBaseURL, network: isTestnet ? .testnet : .mainnet)
    MinterExplorerSDK.initialize(APIURLString: isUITesting ? conf.environment.testExplorerAPIBaseURL : conf.environment.explorerAPIBaseURL,
                                 WEBURLString: conf.environment.explorerWebURL,
                                 websocketURLString: conf.environment.explorerWebsocketURL)
    MinterMySDK.initialize(network: isTestnet ? .testnet : .mainnet)
    

    window = UIWindow()

    let authService = LocalStorageAuthService(storage: SecureStorage(namespace: "Auth"), accountManager: AccountManager())
    let appCoordinator = AppCoordinator(window: window!,
                                        authStateProvider: authService)
    appCoordinator.start()
        .subscribe()
        .disposed(by: disposeBag)

    return true
  }

}
