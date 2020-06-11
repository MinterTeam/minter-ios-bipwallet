//
//  SettingsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum SettingsCoordinatorResult {
  case logout
}

class SettingsCoordinator: BaseCoordinator<SettingsCoordinatorResult> {

  private let navigationController: UINavigationController
  private let pinService: PINService
  private let authService: AuthService

  init(navigationController: UINavigationController, authService: AuthService, pinService: PINService) {
    self.navigationController = navigationController
    self.pinService = pinService
    self.authService = authService

    super.init()
  }

  override func start() -> Observable<SettingsCoordinatorResult> {
    let logoutSubject = PublishSubject<Void>()

    let dependency = SettingsViewModel.Dependency(pinService: self.pinService,
                                                  authService: self.authService,
                                                  appSettings: LocalStorageAppSettings())
    let viewModel = SettingsViewModel(dependency: dependency)
    let controller = SettingsViewController.initFromStoryboard(name: "Settings")
    controller.viewModel = viewModel

    viewModel.output.showPIN.flatMap { (_) -> Observable<PINCoordinatorResult> in
      return self.showPIN()
    }.subscribe(onNext: { [weak self] result in
      switch result {
      case .success:
        break
      case .failure:
        //logout
        self?.logout()
        logoutSubject.onNext(())
        break
      case .cancel:
        break
      }
    }).disposed(by: disposeBag)

    viewModel.output.changePIN.flatMap { [weak self] (_) -> Observable<PINCoordinatorResult> in
      guard let `self` = self else { return Observable.empty() }
      return self.changePIN()
    }.subscribe().disposed(by: disposeBag)

    viewModel.output.didTapLogout.subscribe(onNext: { [weak self] (_) in
      self?.logout()
      logoutSubject.onNext(())
    }).disposed(by: disposeBag)

    navigationController.setViewControllers([controller], animated: false)

    viewModel.output.didTapOurChannel.subscribe(onNext: { _ in
      let conf = Configuration()
      var url: URL?
      if Locale.preferredLanguages.first?.hasPrefix("ru") ?? false {
        url = URL(string: conf.environment.telegramChannelURLRU)
        if !UIApplication.shared.canOpenURL(url!) {
          url = URL(string: conf.environment.telegramChannelWEBURLRU)
        }
      } else {
        url = URL(string: conf.environment.telegramChannelURL)
        if !UIApplication.shared.canOpenURL(url!) {
          url = URL(string: conf.environment.telegramChannelWEBURL)
        }
      }
      guard let resUrl = url else {
        return
      }
      UIApplication.shared.open(resUrl, options: [:], completionHandler: nil)
    }).disposed(by: disposeBag)

    viewModel.output.didTapSupport.subscribe(onNext: { _ in
      let conf = Configuration()
      if let url = URL(string: conf.environment.supportTelegramChannelURL), UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else if let url = URL(string: conf.environment.supportTelegramChannelWEBURL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }).disposed(by: disposeBag)

    return logoutSubject.map {_ in .logout }.take(1)
  }

  func showPIN() -> Observable<PINCoordinatorResult> {
    let coordinator = PINCoordinator(navigationController: navigationController,
                                     state: self.pinService.hasPIN() ? .unset : .set,
                                     pinService: pinService)
    return coordinate(to: coordinator)
  }

  func changePIN() -> Observable<PINCoordinatorResult> {
    let coordinator = PINCoordinator(navigationController: navigationController,
                                     state: .change,
                                     pinService: pinService)
    return coordinate(to: coordinator)
  }

  private func logout() {
    self.authService.logout()
    self.pinService.removePIN()
  }

}
