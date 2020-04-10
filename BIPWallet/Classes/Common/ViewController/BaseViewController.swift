//
//  BaseViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 11.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {

  var hardImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  var disposeBag = DisposeBag()

}

extension UIViewController {

  func showPopup(viewController: PopupViewController,
                 inPopupViewController: PopupViewController? = nil,
                 inTabbar: Bool = true) {

    if nil != inPopupViewController {
      guard let currentViewController = (inPopupViewController?
        .children.last as? PopupViewController) ?? inPopupViewController else {
        return
      }
      currentViewController.addChild(viewController)
      viewController.willMove(toParent: currentViewController)
      currentViewController.didMove(toParent: viewController)
      currentViewController.view.addSubview(viewController.view)
      viewController.view.alpha = 0.0
      viewController.blurView.effect = nil

      guard let popupView = viewController.popupView else {
        return
      }
      popupView.frame = CGRect(x: currentViewController.view.frame.width,
                               y: popupView.frame.origin.y,
                               width: popupView.frame.width,
                               height: popupView.frame.height)
      popupView.center = CGPoint(x: popupView.center.x,
                                 y: currentViewController.view.center.y)
      UIView.animate(withDuration: 0.4,
                     delay: 0,
                     options: .curveEaseInOut,
                     animations: {
        currentViewController.popupView.frame = CGRect(x: -currentViewController.popupView.frame.width,
                                                       y: currentViewController.popupView.frame.origin.y,
                                                       width: currentViewController.popupView.frame.width,
                                                       height: currentViewController.popupView.frame.height)
        popupView.center = currentViewController.view.center
        viewController.view.alpha = 1.0
        currentViewController.popupView.alpha = 0.0
      })
      return
    }
    viewController.modalPresentationStyle = .overFullScreen
    viewController.modalTransitionStyle = .crossDissolve
    if !inTabbar {
      self.present(viewController, animated: true, completion: nil)
    } else {
      self.tabBarController?.present(viewController, animated: true, completion: nil)
    }
  }
}

