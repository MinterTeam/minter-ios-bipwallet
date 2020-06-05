//
//  ValidatorsCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum ValidatorsCoordinatorResult {
  case validator(item: ValidatorItem)
  case cancel
}

class ValidatorsCoordinator: BaseCoordinator<ValidatorsCoordinatorResult> {

  let validatorService: ValidatorService
  let rootViewController: UIViewController

  init(rootViewController: UIViewController, validatorService: ValidatorService) {
    self.rootViewController = rootViewController
    self.validatorService = validatorService
  }

  override func start() -> Observable<ValidatorsCoordinatorResult> {
    let dependency = ValidatorsViewModel.Dependency(validatorService: self.validatorService)
    let viewModel = ValidatorsViewModel(dependency: dependency)
    let controller = ValidatorsViewController.initFromStoryboard(name: "Validators")
    controller.viewModel = viewModel

    let result = Observable.of(
      controller.rx.deallocated.map {_ in .cancel},
      viewModel.output.didSelect.map { (item) -> ValidatorsCoordinatorResult in
        guard let item = item else { return .cancel }
        return ValidatorsCoordinatorResult.validator(item: item)
    }).merge().do(onNext: { (_) in
      controller.dismiss(animated: true, completion: nil)
    })

    rootViewController.present(controller, animated: true) {}

    return result.take(1)
  }

}
