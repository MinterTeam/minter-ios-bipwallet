//
//  AppCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Swinject

protocol AppCoordinator: Coordinator {}

final class AppCoordinatorImpl: BaseCoordinator, AppCoordinator {

  var authStateProvider: AuthStateProvider!
  
  override func start() {
    runAuthFlow()
  }

  override func start(with option: DeepLinkOption?) {
    
//    switch authStateProvider.authState {
//    case false:
//        runAuthFlow(with: option)
//    case true:
//        runMainFlow(with: option)
//    }
  }

  private func runAuthFlow(with deepLink: DeepLinkOption? = nil) {

    let coordinator = assembler.resolver.resolve(WelcomeCoordinator.self, argument: assembler)!
    coordinator.onFinish = { [weak coordinator, weak self] deepLink in
      self?.removeDependency(coordinator)
      self?.runMainFlow(with: deepLink)
    }
    addDependency(coordinator)
    router.setRootModule(coordinator.router, animated: true)
    coordinator.start(with: deepLink)
  }

  private func runMainFlow(with deepLink: DeepLinkOption?) {
    let coordinator = assembler.resolver.resolve(BalanceCoordinator.self, argument: assembler)!
    coordinator.onLogout = { [weak coordinator, weak self] in
        self?.removeDependency(coordinator)
        self?.runAuthFlow()
    }
    addDependency(coordinator)
    router.setRootModule(coordinator.router)
    coordinator.start(with: deepLink)
  }
}
