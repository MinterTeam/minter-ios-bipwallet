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
  private let transactionService: TransactionService
  private let balanceService: BalanceService

  init(window: UIWindow, authService: AuthService, pinService: PINService, transactionService: TransactionService) {
    self.window = window
    self.authService = authService
    self.pinService = pinService
    self.transactionService = transactionService

//    let address = self.authService.selectedAccount()?.address

    self.balanceService = ExplorerBalanceService()
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

        case .failure:
          self.authService.logout()
          self.pinService.removePIN()
          return self.startWelcome().flatMap { self.start() }

        default:
          return self.startWelcome().flatMap { self.start() }
        }
      }).subscribe().disposed(by: disposeBag)
    }
    return Observable.never()
  }

  func start(with url: URL) -> Observable<Void> {
    switch authService.authState {
      case .pinNeeded:
        return startPin().flatMap({ (result) -> Observable<Void> in
          switch result {
          case .success:
            return self.start(with: url)
          default:
            return Observable.empty()
          }
        })

      case .hasAccount:
        return self.start().do(onSubscribed: {
          let rawCoordinator = RawTransactionCoordinator(rootViewController: self.window.rootViewController!, url: url, balanceService: self.balanceService, transactionService: self.transactionService)
          self.coordinate(to: rawCoordinator).timeout(.seconds(3), scheduler: MainScheduler.instance).subscribe().disposed(by: self.disposeBag)
        })

      default:
        return Observable.empty()
    }
  }

  private func startWelcome() -> Observable<Void> {
    return coordinate(to: WelcomeCoordinator(window: window, authService: self.authService))
  }

  private func startWallet() -> Observable<Void> {
    let coordinator = WalletCoordinator(window: window, authService: authService, pinService: self.pinService, transactionService: transactionService, balanceService: balanceService)
    return coordinate(to: coordinator)
  }

  private func startPin() -> Observable<PINCoordinatorResult> {
    let navigation = ClearBarNavigationController()
    window.rootViewController = navigation

    let options: UIView.AnimationOptions = .transitionCrossDissolve

    // The duration of the transition animation, measured in seconds.
    let duration: TimeInterval = 0.3

    // Creates a transition animation.
    // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
    UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
    { completed in
        // maybe do something on completion here
    })

    let coordinator = PINCoordinator(navigationController: navigation,
                                     pinService: self.pinService)
    return coordinate(to: coordinator)
  }

}
