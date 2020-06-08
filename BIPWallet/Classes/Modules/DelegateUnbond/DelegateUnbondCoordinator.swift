//
//  DelegateUnbondCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class DelegateUnbondCoordinator: BaseCoordinator<Void> {

  let rootViewController: UIViewController
  let balanceService: BalanceService
  var validatorItem: ValidatorItem?
  let validatorService: ValidatorService
  var isUnbond = false
  var maxUnbondAmounts: [String: Decimal]?
  var coin: String?
  var confirmPopupCoordiantor: DelegateUnbondConfirmPopupCoordinator?
  let controller = DelegateUnbondViewController.initFromStoryboard(name: "DelegateUnbond")

  init(rootViewController: UIViewController, balanceService: BalanceService, validatorService: ValidatorService) {
    self.rootViewController = rootViewController
    self.balanceService = balanceService
    self.validatorService = validatorService
  }

  override func start() -> Observable<Void> {
    let accountService = LocalStorageAccountService()

    let gateService = ExplorerGateService()
    
    gateService.updateGas()

    let dependency = DelegateUnbondViewModel.Dependency(validatorService: validatorService,
                                                        balanceService: balanceService,
                                                        gateService: gateService,
                                                        accountService: accountService)

    let viewModel = DelegateUnbondViewModel(validator: validatorItem,
                                            coinName: coin,
                                            isUnbond: isUnbond,
                                            maxUnbondAmounts: maxUnbondAmounts,
                                            dependency: dependency)

    controller.viewModel = viewModel

    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .coverVertical

    rootViewController.present(controller, animated: true, completion: nil)

    viewModel.output.didTapShowValidators.flatMap { [weak self] (_) -> Observable<ValidatorsCoordinatorResult> in
      guard let `self` = self else { return Observable.empty() }
      return self.showValidators(rootViewController: self.controller,
                                 validatorService: self.validatorService)
    }.subscribe(onNext: { result in
      switch result {
      case .validator(let validator):
        viewModel.validator = validator
      case .cancel:
        break
      }
    }).disposed(by: disposeBag)

    viewModel.output.showConfirmation.flatMap({ [weak self] (val) -> Observable<DelegateUnbondConfirmPopupCoordinatorResult> in
      guard let `self` = self else { return Observable.empty() }

      self.confirmPopupCoordiantor = DelegateUnbondConfirmPopupCoordinator(rootViewController: self.controller,
                                                                           isUnbond: self.isUnbond,
                                                                           amountText: val.0,
                                                                           validatorText: val.1 ?? "")

      guard let confirmPopupCoordiantor = self.confirmPopupCoordiantor else { return Observable.empty() }

      return self.coordinate(to: confirmPopupCoordiantor)
    }).flatMap { (result) -> Observable<Event<String?>> in
      switch result {
      case .confirmed:
        return viewModel.performSend()

      case .canceled:
        return Observable.empty()
      }
    }.flatMap({ (val) -> Observable<Void> in
      switch val {
      case .next(let hash):
        return self.confirmPopupCoordiantor!.showSucceed("Successful " + (self.isUnbond ? "unbond" : "delegation"), hash: hash)

      case .error(_):
        self.confirmPopupCoordiantor?.close()
        return Observable.empty()

      case .completed:
        return Observable.empty()
      }
    }).subscribe().disposed(by: disposeBag)

    return controller.rx.deallocated.map { _ in Void() }.take(1)
  }

  func showValidators(rootViewController: UIViewController, validatorService: ValidatorService) -> Observable<ValidatorsCoordinatorResult> {
    let coordinator = ValidatorsCoordinator(rootViewController: rootViewController, validatorService: validatorService)
    return coordinate(to: coordinator)
  }

}
