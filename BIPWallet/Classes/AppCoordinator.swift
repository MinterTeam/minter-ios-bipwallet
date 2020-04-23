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

  var authService: AuthService
  private let pinService: PINService

  init(window: UIWindow, authService: AuthService, pinService: PINService) {
    self.window = window
    self.authService = authService
    self.pinService = pinService
  }

  override func start() -> Observable<Void> {
    switch authService.authState {
    case .hasAccount:
      startWallet().flatMap { (_) -> Observable<Void> in
        return self.start()
      }.subscribe().disposed(by: self.disposeBag)

    case .noAccount:
      startWelcome().flatMap { (_) -> Observable<Void> in
        return self.start()
      }.subscribe().disposed(by: self.disposeBag)

    case .pinNeeded:
      startPin().flatMap({ (result) -> Observable<Void> in
        switch result {
        case .success:
          return self.start()

        default:
          return self.startWelcome()
        }
      }).subscribe().disposed(by: disposeBag)
    }
    return Observable.never()
  }

  private func startWelcome() -> Observable<Void> {
    return coordinate(to: WelcomeCoordinator(window: window, authService: self.authService))
  }

  private func startWallet() -> Observable<Void> {
    return coordinate(to: WalletCoordinator(window: window, authService: authService, pinService: self.pinService))
  }

  private func startPin() -> Observable<PINCoordinatorResult> {
    let navigation = UINavigationController()
    window.rootViewController = navigation
    let coordinator = PINCoordinator(navigationController: navigation, pinService: self.pinService)
    return coordinate(to: coordinator)
  }

}
