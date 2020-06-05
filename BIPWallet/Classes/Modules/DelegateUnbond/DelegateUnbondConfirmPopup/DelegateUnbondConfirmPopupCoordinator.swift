//
//  ConvertPopupCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum DelegateUnbondConfirmPopupCoordinatorResult {
  case confirmed
  case canceled
}

class DelegateUnbondConfirmPopupCoordinator: BaseCoordinator<DelegateUnbondConfirmPopupCoordinatorResult> {

  private weak var rootViewController: UIViewController?
  let amountText: String?
  let validatorText: String?
  let title: String
  let desc: String
  let toFrom: String

  init(rootViewController: UIViewController, isUnbond: Bool = false, amountText: String?, validatorText: String?) {
    self.rootViewController = rootViewController
    self.amountText = amountText
    self.validatorText = validatorText
    self.title = "Confirm " + (isUnbond ? "Unbond" : "Delegation")
    self.desc = "You will " + (isUnbond ? "unbond" : "delegate")
    self.toFrom = isUnbond ? "from" : "to"

    self.controller = DelegateUnbondConfirmPopupViewController.initFromStoryboard(name: "DelegateUnbondConfirmPopup")
  }

  private weak var controller: DelegateUnbondConfirmPopupViewController?

  override func start() -> Observable<DelegateUnbondConfirmPopupCoordinatorResult> {
    let dependency = DelegateUnbondConfirmPopupViewModel.Dependency()
    let viewModel = DelegateUnbondConfirmPopupViewModel(dependency: dependency,
                                                        title: title,
                                                        desc: desc,
                                                        toFrom: toFrom,
                                                        amountText: amountText,
                                                        validatorText: validatorText)

    controller?.viewModel = viewModel

    controller?.modalPresentationStyle = .overFullScreen
    controller?.modalTransitionStyle = .coverVertical

    guard let controller = controller else { return Observable.empty() }

    rootViewController?.showPopup(viewController: controller, inPopupViewController: nil, inTabbar: false)

    let result = Observable.of(viewModel.output.actionDidTap.map {_ in DelegateUnbondConfirmPopupCoordinatorResult.confirmed },
                               controller.rx.deallocated.map { _ in DelegateUnbondConfirmPopupCoordinatorResult.canceled }).merge()

    return result
  }

  func showSucceed(_ message: String?, hash: String?) -> Observable<Void> {
    guard let controller = controller, let rootViewController = rootViewController else { return Observable.just(()) }
    let coordiantor = DelegateUnbondSucceedPopupCoordinator(rootViewController: rootViewController,
                                                            popupViewController: controller,
                                                            message: message,
                                                            transactionHash: hash)
    return coordinate(to: coordiantor)
  }

  func close() {
    controller?.dismiss(animated: true, completion: nil)
  }

}
