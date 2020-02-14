//
//  AppDelegate.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 07.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  lazy var appCoordinator = self.makeAppCoordinator()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    self.window = UIWindow(frame: UIScreen.main.bounds)
    self.appCoordinator.start()
    self.window?.makeKeyAndVisible()

    return true
  }

  func makeAppCoordinator() -> Coordinator {
    let assembler = Assembler([
      AppCoordinatorAssembly()
    ], container: Container())
    return assembler.resolver.resolve(AppCoordinator.self,
                                      arguments: assembler, window)!
  }

}

