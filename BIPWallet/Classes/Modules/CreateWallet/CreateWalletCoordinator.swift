//
//  CreateWalletCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 18/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import CardPresentationController

class CreateWalletCoordinator: BaseCoordinator<Void> {

  private let rootViewController: UIViewController
  private let authService: AuthService

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
  }

  override func start() -> Observable<Void> {

    let viewModel = CreateWalletViewModel(dependency: CreateWalletViewModel.Dependency(authService: authService))
    let controller = CreateWalletViewController.initFromStoryboard(name: "CreateWallet")
    controller.viewModel = viewModel

    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

//    viewModel.output.viewDidDisappear.subscribe(onNext: { [weak self] (_) in
//      self?.rootViewController.hideBlurOverview()
//    }).disposed(by: disposeBag)

    var cardConfig = CardConfiguration()
    cardConfig.horizontalInset = 0.0
    cardConfig.verticalInset = 0.0
    cardConfig.verticalSpacing = 0.0
    cardConfig.cornerRadius = 0.0
    cardConfig.backFadeAlpha = 1.0
    cardConfig.dismissAreaHeight = 5
    CardPresentationController.useSystemPresentationOniOS13 = true

//    rootViewController.showBlurOverview()
    rootViewController.present(controller, animated: true, completion: nil)

//    rootViewController.presentCard(ClearBarNavigationController(rootViewController: controller),
//                                   configuration: cardConfig,
//                                   animated: true)

    return Observable.merge(viewModel.output.mnemonicSaved, viewModel.output.viewDidDisappear.map { _ in Void() })
  }

}
