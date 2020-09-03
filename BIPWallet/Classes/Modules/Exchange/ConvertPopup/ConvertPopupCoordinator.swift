//
//  ConvertPopupCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

enum ConvertPopupCoordinatorResult {
  case confirmed
  case canceled
}

class ConvertPopupCoordinator: BaseCoordinator<ConvertPopupCoordinatorResult> {

  private weak var rootViewController: UIViewController?
  let fromText: String?
  let toText: String?

  init(rootViewController: UIViewController, fromText: String?, toText: String?) {
    self.rootViewController = rootViewController
    self.fromText = fromText
    self.toText = toText

    self.controller = ConvertPopupViewController.initFromStoryboard(name: "ConvertPopup")
  }

  private weak var controller: ConvertPopupViewController?

  override func start() -> Observable<ConvertPopupCoordinatorResult> {
    let dependency = ConvertPopupViewModel.Dependency()
    let viewModel = ConvertPopupViewModel(dependency: dependency, fromText: fromText, toText: toText)

    controller?.viewModel = viewModel

    controller?.modalPresentationStyle = .overFullScreen
    controller?.modalTransitionStyle = .coverVertical

    guard let controller = controller else { return Observable.empty() }

    rootViewController?.showPopup(viewController: controller, inPopupViewController: nil, inTabbar: false)

    let result = Observable.of(viewModel.output.actionDidTap.map {_ in ConvertPopupCoordinatorResult.confirmed },
                               controller.rx.deallocated.map { _ in ConvertPopupCoordinatorResult.canceled }).merge()
 
    return result
  }

  func showSucceed(_ message: String?, hash: String?, shouldHideActionButton: Bool = false) -> Observable<Void> {
    guard let controller = controller, let rootViewController = rootViewController else { return Observable.just(()) }

    let coordiantor = ConvertSucceedPopupCoordinator(rootViewController: rootViewController,
                                                     popupViewController: controller,
                                                     message: message,
                                                     transactionHash: hash,
                                                     shouldHideActionButton: shouldHideActionButton)
    return coordinate(to: coordiantor)
  }

  func close() {
    controller?.dismiss(animated: true, completion: nil)
  }

}
