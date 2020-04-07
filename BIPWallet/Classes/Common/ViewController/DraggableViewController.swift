//
//  DraggableViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 31.03.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

@objc
protocol DraggableViewDelegate: class {
  @objc optional func panGestureDidBegin(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint)
  @objc optional func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint)
  @objc optional func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint)
  @objc optional func panGestureStateToOriginal(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint)
}

class DraggableView: UIView {

  weak var delegate: DraggableViewDelegate?

  var panGestureRecognizer: UIPanGestureRecognizer?
  var originalPosition: CGPoint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setUp()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setUp()
  }

  func setUp() {
    isUserInteractionEnabled = true
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
    self.addGestureRecognizer(panGestureRecognizer!)
  }

  @objc
  func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    let translation = panGesture.translation(in: superview)
    let velocityInView = panGesture.velocity(in: superview)

    switch panGesture.state {
    case .began:
      originalPosition = self.center
      delegate?.panGestureDidBegin?(panGesture, originalCenter: originalPosition!)
      break

    case .changed:
      self.frame.origin = CGPoint(
          x: originalPosition!.x - self.bounds.midX + translation.x,
          y: originalPosition!.y  - self.bounds.midY + translation.y
      )
      delegate?.panGestureDidChange?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break

    case .ended:
      delegate?.panGestureDidEnd?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break

    default:
      delegate?.panGestureStateToOriginal?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break
    }
  }

}

class SnapDraggable: DraggableView, DraggableViewDelegate {

  override init(frame: CGRect) {
    super.init(frame: frame)
    delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    delegate = self
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .curveEaseInOut, animations: {
      self.center = originalCenter
    }, completion: nil)
  }

}

class VerticalSnapDraggableView: DraggableView, DraggableViewDelegate {

  override init(frame: CGRect) {
    super.init(frame: frame)
    delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    delegate = self
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .curveEaseInOut, animations: {
      self.center = originalCenter
    }, completion: nil)
  }

  @objc
  override func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    let translation = panGesture.translation(in: superview)
    let velocityInView = panGesture.velocity(in: superview)

    switch panGesture.state {
    case .began:
      originalPosition = self.center
      delegate?.panGestureDidBegin?(panGesture, originalCenter: originalPosition!)
      break

    case .changed:
      self.frame.origin = CGPoint(
          x: originalPosition!.x - self.bounds.midX,
          y: originalPosition!.y  - self.bounds.midY + translation.y
      )
      delegate?.panGestureDidChange?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break

    case .ended:
      delegate?.panGestureDidEnd?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break

    default:
      delegate?.panGestureStateToOriginal?(panGesture, originalCenter: originalPosition!, translation: translation, velocityInView: velocityInView)
      break
    }
  }

}
