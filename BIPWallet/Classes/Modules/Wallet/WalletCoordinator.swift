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

  private let window: UIWindow

  init(window: UIWindow) {
    self.window = window
  }

  override func start() -> Observable<Void> {
    let controller = WalletViewController.initFromStoryboard(name: "Wallet")
    controller.viewControllers = []
    controller.viewModel = WalletViewModel(dependency: WalletViewModel.Dependency())

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
    let balanceCoordiantor = BalanceCoordinator(navigationController: balance)
    coordinate(to: balanceCoordiantor).subscribe().disposed(by: disposeBag)

    let sendTabbarItem = UITabBarItem(title: "Wallets".localized(),
                                      image: UIImage(named: "SendIcon"),
                                      selectedImage: nil)

    let send = UINavigationController()
    send.tabBarItem = sendTabbarItem

    let sendCoordinator = SendCoordinator(navigationController: send)
    coordinate(to: sendCoordinator).subscribe().disposed(by: disposeBag)

//    let settingsTabbarItem = UITabBarItem(title: "Wallets".localized(),
//                                          image: UIImage(named: "SettingsIcon"),
//                                          selectedImage: nil)
//    let settings = SettingsCoordinator(tabbarItem: settingsTabbarItem)

//    let coordinators = [balance, send, settings].map { (coordinator) -> Observable<UIViewController> in
//      return self.coordinate(to: coordinator)
//    }
//    Observable.combineLatest(coordinators).subscribe(onNext: { (vcs) in
//      controller.viewControllers = vcs
//    }).disposed(by: disposeBag)

    controller.viewControllers = [balance, send]


    return Observable.never()
  }

}