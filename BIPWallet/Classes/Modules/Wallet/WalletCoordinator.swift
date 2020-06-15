//
//  WalletCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class WalletCoordinator: BaseCoordinator<Void> {

  var showPIN = PublishSubject<Void>()

  private let window: UIWindow

  let authService: AuthService
  let balanceService: BalanceService
  let pinService: PINService
  let transactionService: TransactionService

  init(window: UIWindow,
       authService: AuthService,
       pinService: PINService,
       transactionService: TransactionService,
       balanceService: BalanceService) {

    self.window = window
    self.authService = authService
    self.pinService = pinService
    self.transactionService = transactionService
    self.balanceService = balanceService
    let address = (self.authService.selectedAccount()?.address ?? "")
    try? self.balanceService.changeAddress(address)

    super.init()
  }

  override func start() -> Observable<Void> {
    let contactsService = LocalStorageContactsService()
    let validatorService = ExplorerValidatorService()
    validatorService.updateValidators()

    let recipientInfoService = ExplorerRecipientInfoService(contactsService: contactsService)

    let controller = WalletViewController.initFromStoryboard(name: "Wallet")
    controller.viewControllers = []
    controller.viewModel = WalletViewModel(dependency: WalletViewModel.Dependency())
    controller.tabBar.tintColor = .mainPurpleColor()

    window.rootViewController = controller

    let options: UIView.AnimationOptions = .transitionCrossDissolve

    let duration: TimeInterval = 0.3

    UIView.transition(with: window,
                      duration: duration,
                      options: options,
                      animations: {},
                      completion: { completed in
    })

    let balanceTabbarItem = UITabBarItem(title: "Wallets".localized(),
                                         image: UIImage(named: "WalletsIcon"),
                                         selectedImage: nil)
    let balance = UINavigationController()
    balance.tabBarItem = balanceTabbarItem
    let balanceCoordiantor = BalanceCoordinator(navigationController: balance,
                                                balanceService: balanceService,
                                                authService: authService,
                                                recipientInfoService: recipientInfoService,
                                                transactionService: transactionService,
                                                validatorService: validatorService
                                                )
    coordinate(to: balanceCoordiantor).subscribe().disposed(by: disposeBag)

    let sendTabbarItem = UITabBarItem(title: "Send".localized(),
                                      image: UIImage(named: "SendIcon"),
                                      selectedImage: nil)

    let send = WhiteNavigationController()
    send.tabBarItem = sendTabbarItem

    let sendCoordinator = SendCoordinator(navigationController: send,
                                          balanceService: balanceService,
                                          authService: authService,
                                          contactsService: contactsService,
                                          recipientInfoService: recipientInfoService,
                                          validatorService: validatorService
                                          )
    coordinate(to: sendCoordinator).subscribe().disposed(by: disposeBag)

    //Passing address/public key which was scanned on Balance screen
    balanceCoordiantor.didScanRecipient.subscribe(onNext: { val in
      sendCoordinator.recipient.onNext(val)
      controller.selectedIndex = 1
    }).disposed(by: disposeBag)

    let settingsTabbarItem = UITabBarItem(title: "Settings".localized(),
                                          image: UIImage(named: "SettingsIcon"),
                                          selectedImage: nil)

    let settings = WhiteNavigationController()
    settings.tabBarItem = settingsTabbarItem

    let settingsCoordinator = SettingsCoordinator(navigationController: settings,
                                                  authService: self.authService,
                                                  pinService: self.pinService)

    controller.viewControllers = [balance, send, settings]

//    showPIN.flatMap {self.startPin()}.subscribe(onNext: { _ in
//      self.window.rootViewController = controller
//    }).disposed(by: disposeBag)

    return coordinate(to: settingsCoordinator).map {_ in Void() }
  }

//  private func startPin() -> Observable<PINCoordinatorResult> {
//    let navigation = ClearBarNavigationController()
//    window.rootViewController = navigation
//
//    let options: UIView.AnimationOptions = .transitionCrossDissolve
//
//    // The duration of the transition animation, measured in seconds.
//    let duration: TimeInterval = 0.3
//
//    // Creates a transition animation.
//    // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
//    UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
//    { completed in
//        // maybe do something on completion here
//    })
//
//    let coordinator = PINCoordinator(navigationController: navigation, pinService: self.pinService)
//    return coordinate(to: coordinator)
//  }

}
