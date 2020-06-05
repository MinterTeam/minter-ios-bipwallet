//
//  SendSucceedPopupCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 26/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum SendSucceedPopupCoordinatorResult {
  case showAddAddress(address: String?)
  case viewTransaction
  case cancel
}

class SendSucceedPopupCoordinator: BaseCoordinator<SendSucceedPopupCoordinatorResult> {

  private var shouldHideActionButton: Bool = false
  let recipient: String?
  let rootViewController: UIViewController
  let popupViewController: PopupViewController?
  let address: String?

  init(rootViewController: UIViewController,
       inPopupViewController: PopupViewController?,
       recipient: String?,
       address: String?,
       shouldHideActionButton: Bool) {

    self.recipient = recipient
    self.popupViewController = inPopupViewController
    self.rootViewController = rootViewController
    self.address = address
    self.shouldHideActionButton = shouldHideActionButton

    super.init()
  }

  override func start() -> Observable<SendSucceedPopupCoordinatorResult> {
    let dependency = SendSucceedPopupViewModel.Dependency()
    let viewModel = SendSucceedPopupViewModel(dependency: dependency,
                                              shouldHideActionButton: shouldHideActionButton,
                                              recipient: recipient)

    let controller = SendSucceedPopupViewController.initFromStoryboard(name: "SendSucceedPopup")
    controller.viewModel = viewModel

    rootViewController.showPopup(viewController: controller, inPopupViewController: popupViewController)

    let actionResult = viewModel.output.didTapAction.map { SendSucceedPopupCoordinatorResult.showAddAddress(address: self.address) }
    let secondaryResult = viewModel.output.didTapSecondary.map { SendSucceedPopupCoordinatorResult.viewTransaction }
    let closeResult = viewModel.output.didTapClose.map { SendSucceedPopupCoordinatorResult.cancel }

    let result = Observable.of(closeResult, controller.rx.deallocated.map { SendSucceedPopupCoordinatorResult.cancel }, secondaryResult, actionResult).merge().do(onNext: { (_) in
      controller.dismiss(animated: true, completion: nil)
    })

    return result.take(1)
  }

}
