//
//  PINCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum PINCoordinatorResult {
  case success
  case failure
  case cancel
}

enum PINCoordinatorState {
  case unlock //checking PIN to unlock
  case set //setting the PIN
  case confirm //checking if PIN correct
  case unset
  case change
}

class PINCoordinator: BaseCoordinator<PINCoordinatorResult> {

  private let navigationController: UINavigationController
  private(set) var state: PINCoordinatorState
  private let pinService: PINService

  private var pinToConfirm: String?

  init(navigationController: UINavigationController, state: PINCoordinatorState = .unlock, pinService: PINService) {
    self.navigationController = navigationController
    self.state = state
    self.pinService = pinService
  }

  override func start() -> Observable<PINCoordinatorResult> {
    let viewController = self.createViewController()

    if let rootVC = self.navigationController.viewControllers.first {
      self.navigationController.setViewControllers([rootVC, viewController], animated: true)
    } else {
      navigationController.pushViewController(viewController, animated: true)
    }

    let coordinatorResult = PublishSubject<PINCoordinatorResult>()

    viewController.viewModel.pin.filter{ $0 != "" }.subscribe(onNext: { (pin) in
      if self.state == .unlock || self.state == .unset || self.state == .change {
        //if unlocking -> check pin
        do {
          if try self.pinService.unlock(with: pin) {
            if self.state == .unset {
              self.pinService.removePIN()
            }
            if self.state == .change {
              let coordinator = PINCoordinator(navigationController: self.navigationController, state: .set, pinService: self.pinService)
              coordinator.start().subscribe(coordinatorResult).disposed(by: self.disposeBag)
            } else {
            //unlocked
              coordinatorResult.onNext(.success)
              self.navigationController.popViewController(animated: true)
            }
          } else {
            //shakeError
            viewController.viewModel.shakeError.onNext(())
          }
        } catch let error {
          //failure
          coordinatorResult.onNext(.failure)
        }
      } else if self.state == .set {
        //show confirm
        self.pinToConfirm = pin
        let coordinator = PINCoordinator(navigationController: self.navigationController, state: .confirm, pinService: self.pinService)
        coordinator.pinToConfirm = pin
        coordinator.start().subscribe(coordinatorResult).disposed(by: self.disposeBag)
      } else {
        //confirming. check if correct
        if let pinToConfirm = self.pinToConfirm, pin == pinToConfirm {
          self.pinService.setPIN(code: pin)
          self.navigationController.popToRootViewController(animated: true)
          coordinatorResult.onNext(.success)
        } else {
          //error
          viewController.viewModel.shakeError.onNext(())
        }
      }
      //If settings -> ask pin once -> send result
    }).disposed(by: disposeBag)

    viewController.viewModel.output.unlockedWithBiometrics.map { _ -> PINCoordinatorResult in
      return PINCoordinatorResult.success
    }.subscribe(coordinatorResult).disposed(by: disposeBag)

    return coordinatorResult.take(1)
  }

  func createViewController() -> PINViewController {
    let viewModel = PINViewModel(dependency: PINViewModel.Dependency(pinService: self.pinService))
    viewModel.isBiometricEnabled = pinService.isBiometricEnabled()
    if state == .confirm {
      viewModel.desc = "Please confirm a 4-digit PIN".localized()
    } else {
      viewModel.desc = "Please confirm a 4-digit PIN".localized()
    }
    if self.state != .unlock {
//      viewModel.isBiometricEnabled = false
    }
    let viewController = PINViewController.initFromStoryboard(name: "PIN")
    viewController.viewModel = viewModel
    viewController.modalPresentationStyle = .fullScreen
    viewController.modalTransitionStyle = .crossDissolve
    return viewController
  }

}
