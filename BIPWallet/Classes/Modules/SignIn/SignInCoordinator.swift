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

    rootViewController.present(controller, animated: true, completion: nil)

    let result = Observable.merge(viewModel.output.mnemonicSaved, viewModel.output.viewDidDisappear.map { _ in Void() }).take(1).share()
    result.subscribe(onNext: { (_) in
      controller.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)

    return result
  }

}
