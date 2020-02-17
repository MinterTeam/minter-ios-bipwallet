//
//  AppDelegate.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var disposeBag = DisposeBag()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    window = UIWindow()

    let appCoordinator = AppCoordinator(window: window!,
                                        authStateProvider: LocalStorageAuthService(storage: KeychainAuthStorage()))
    appCoordinator.start()
        .subscribe()
        .disposed(by: disposeBag)

    return true
  }

}
