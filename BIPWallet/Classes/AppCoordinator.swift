//
//  AppCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import RxSwift

final class AppCoordinator: BaseCoordinator<Void> {

  private let window: UIWindow

  var authStateProvider: AuthStateProvider

  init(window: UIWindow, authStateProvider: AuthStateProvider) {
    self.window = window
    self.authStateProvider = authStateProvider
  }

  override func start() -> Observable<Void> {
    switch authStateProvider.authState {
    case .hasAccount:
      return startWallet()

    case .noAccount:
      return startWelcome().flatMap { (_) -> Observable<Void> in
        return self.startWallet()
      }

    case .pinNeeded:
      return startPin()
    }
  }

  private func startWelcome() -> Observable<Void> {
    return coordinate(to: WelcomeCoordinator(window: window))
  }

  private func startWallet() -> Observable<Void> {
    return coordinate(to: WalletCoordinator(window: window))
  }

  private func startPin() -> Observable<Void> {
    return coordinate(to: BalanceCoordinator(window: window))
  }

}
