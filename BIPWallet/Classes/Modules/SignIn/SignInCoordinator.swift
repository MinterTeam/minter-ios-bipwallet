//
//  SignInCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import DeckTransition
import CardPresentationController

class SignInCoordinator: BaseCoordinator<Void> {

  private let rootViewController: UIViewController
  private let authService: AuthService

  init(rootViewController: UIViewController, authService: AuthService) {
    self.rootViewController = rootViewController
    self.authService = authService
  }

  override func start() -> Observable<Void> {
    let controller = SignInViewController.initFromStoryboard(name: "SignIn")
    let viewModel = SignInViewModel(dependency: SignInViewModel.Dependency(authService: authService))
    controller.viewModel = viewModel

    controller.modalTransitionStyle = .coverVertical
    controller.modalPresentationStyle = .overCurrentContext

//    controller.rx.viewWillDisappear.subscribe(onNext: { [weak self] (_) in
//      self?.rootViewController.hideBlurOverview()
//    }).disposed(by: disposeBag)
//
//    controller.rx.viewWillAppear.subscribe(onNext: { [weak self] (_) in
//      self?.rootViewController.showBlurOverview()
//    }).disposed(by: disposeBag)

//    var cardConfig = CardConfiguration()
//    cardConfig.horizontalInset = 0.0
//    cardConfig.verticalInset = 0.0
//    cardConfig.verticalSpacing = 0.0
//    cardConfig.cornerRadius = 0.0
//    cardConfig.backFadeAlpha = 1.0
//    cardConfig.dismissAreaHeight = 5
//    CardPresentationController.useSystemPresentationOniOS13 = false
//
//    rootViewController.presentCard(ClearBarNavigationController(rootViewController: controller),
//                                   configuration: cardConfig,
//                                   animated: true)

    rootViewController.present(controller, animated: true, completion: nil)

    return Observable.merge(viewModel.output.mnemonicSaved, viewModel.output.viewDidDisappear.map { _ in Void() }).take(1)
  }

}
