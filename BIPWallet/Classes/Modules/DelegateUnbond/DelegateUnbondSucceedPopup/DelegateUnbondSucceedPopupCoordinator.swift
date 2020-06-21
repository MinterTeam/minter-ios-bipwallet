//
//  ConvertSucceedPopupCoordinator.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 15/05/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices
import MinterExplorer

class DelegateUnbondSucceedPopupCoordinator: BaseCoordinator<Void> {

  private weak var rootViewController: UIViewController?
  private weak var popupViewController: PopupViewController?
  private let message: String?
  private let desc: String?
  private let transactionHash: String?

  init(rootViewController: UIViewController, popupViewController: PopupViewController, message: String?, desc: String?, transactionHash: String?) {
    self.rootViewController = rootViewController
    self.popupViewController = popupViewController
    self.message = message
    self.desc = desc
    self.transactionHash = transactionHash
  }

  override func start() -> Observable<Void> {
    let dependency = DelegateUnbondSucceedPopupViewModel.Dependency()
    let viewModel = DelegateUnbondSucceedPopupViewModel(dependency: dependency, message: self.message, desc: self.desc)
    let controller = DelegateUnbondSucceedPopupViewController.initFromStoryboard(name: "DelegateUnbondSucceedPopup")
    controller.viewModel = viewModel

    rootViewController?.showPopup(viewController: controller, inPopupViewController: popupViewController, inTabbar: false)

    viewModel.output.didTapAction.map({ [weak self] (_) -> URL? in
      guard let transactionHash = self?.transactionHash else { return nil }
      return self?.explorerURL(hash: transactionHash)
    }).subscribe(onNext: { [weak controller, weak self, weak rootViewController] (url) in
      guard let url = url else { return }
      controller?.dismiss(animated: true, completion: {
        let safari = SFSafariViewController(url: url)
        rootViewController?.present(safari, animated: true) {}
      })
    }).disposed(by: disposeBag)

    return controller.rx.deallocated.debug().map {_ in}
  }

  func explorerURL(hash: String?) -> URL? {
    if let hash = hash {
      return URL(string: MinterExplorerBaseURL! + "/transactions/" + hash)
    }
    return nil
  }

}
