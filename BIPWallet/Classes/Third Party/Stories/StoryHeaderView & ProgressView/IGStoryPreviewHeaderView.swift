//
//  IGStoryPreviewHeaderView.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit

protocol StoryPreviewHeaderProtocol: class {
  func didTapCloseButton()
  func didTapShareButton()
}

fileprivate let maxSnaps = 30

//Identifiers
public let progressIndicatorViewTag = 88
public let progressViewTag = 99

final class IGStoryPreviewHeaderView: UIView {

  // MARK: - iVars

  public weak var delegate: StoryPreviewHeaderProtocol?

  fileprivate var snapsPerStory: Int = 0

  public var story: IGStory? {
    didSet {
      snapsPerStory = (story?.snapsCount)! < maxSnaps ? (story?.snapsCount)! : maxSnaps
    }
  }

  fileprivate var progressView: UIView?

  private let detailView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var closeButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(#imageLiteral(resourceName: "ic_close"), for: .normal)
    button.addTarget(self, action: #selector(didTapClose(_:)), for: .touchUpInside)
    return button
  }()

  private lazy var shareButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(#imageLiteral(resourceName: "ig_share"), for: .normal)
    button.addTarget(self, action: #selector(didTapShare(_:)), for: .touchUpInside)
    return button
  }()

  public var getProgressView: UIView {
    if let progressView = self.progressView {
      return progressView
    }
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    self.progressView = v
    self.addSubview(self.getProgressView)
    return v
  }

  // MARK: - Overriden functions

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.frame = frame
    applyShadowOffset()
    loadUIElements()
    installLayoutConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  var isDark: Bool = true {
    didSet {
//      if isDark {
        self.closeButton.tintColor = .white
        self.shareButton.tintColor = .white
//      } else {
//        self.closeButton.tintColor = .black
//        self.shareButton.tintColor = .black
//      }
    }
  }

  var showShare: Bool = true {
    didSet {
      self.shareButton.isHidden = !showShare
    }
  }

  // MARK: - Private functions

  private func loadUIElements() {
    backgroundColor = .clear
    isDark = true
    addSubview(getProgressView)
    addSubview(detailView)
    addSubview(closeButton)
    addSubview(shareButton)
  }

  private func installLayoutConstraints() {
    //Setting constraints for progressView
    let pv = getProgressView
    NSLayoutConstraint.activate([
      pv.igLeftAnchor.constraint(equalTo: self.igLeftAnchor),
      pv.igTopAnchor.constraint(equalTo: self.igTopAnchor, constant: 4),
      self.igRightAnchor.constraint(equalTo: pv.igRightAnchor),
      pv.heightAnchor.constraint(equalToConstant: 10)
    ])

    layoutIfNeeded() //To make snaperImageView round. Adding this to somewhere else will create constraint warnings.

    //Setting constraints for detailView
    NSLayoutConstraint.activate([
      detailView.heightAnchor.constraint(equalToConstant: 40),
      closeButton.igLeftAnchor.constraint(equalTo: detailView.igLeftAnchor, constant: -2),
      shareButton.igRightAnchor.constraint(equalTo: detailView.igRightAnchor, constant: 2)
    ])

    //Setting constraints for closeButton and shareButton
    NSLayoutConstraint.activate([
      closeButton.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: -2),
      closeButton.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor, constant: -2),

      shareButton.igRightAnchor.constraint(equalTo: self.igRightAnchor, constant: 2),
      shareButton.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor, constant: -2),

      closeButton.widthAnchor.constraint(equalToConstant: 60),
      closeButton.heightAnchor.constraint(equalToConstant: 80),
      shareButton.widthAnchor.constraint(equalToConstant: 60),
      shareButton.heightAnchor.constraint(equalToConstant: 80)
    ])
  }

  private func applyShadowOffset() {
    layer.masksToBounds = false
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.5
    layer.shadowOffset = CGSize(width: -1, height: 1)
    layer.shadowRadius = 1
  }

  private func applyProperties<T: UIView>(_ view: T, with tag: Int? = nil, alpha: CGFloat = 1.0) -> T {
    view.layer.cornerRadius = 1
    view.layer.masksToBounds = true
    view.backgroundColor = UIColor.white.withAlphaComponent(alpha)
    if let tagValue = tag {
      view.tag = tagValue
    }
    return view
  }

  // MARK: - Selectors

  @objc func didTapClose(_ sender: UIButton) {
    delegate?.didTapCloseButton()
  }

  @objc func didTapShare(_ sender: UIButton) {
    delegate?.didTapShareButton()
  }

  // MARK: - Public functions

  public func clearTheProgressorSubviews() {
    getProgressView.subviews.forEach { v in
      v.subviews.forEach { v in (v as! IGSnapProgressView).stop() }
      v.removeFromSuperview()
    }
  }

  public func clearAllProgressors() {
    clearTheProgressorSubviews()
    getProgressView.removeFromSuperview()
    self.progressView = nil
  }

  public func clearSnapProgressor(at index:Int) {
    getProgressView.subviews[index].removeFromSuperview()
  }

  public func createSnapProgressors() {
    print("Progressor count: \(getProgressView.subviews.count)")
    let padding: CGFloat = 8 //GUI-Padding
    let height: CGFloat = 2
    var pvIndicatorArray: [IGSnapProgressIndicatorView] = []
    var pvArray: [IGSnapProgressView] = []

    // Adding all ProgressView Indicator and ProgressView to seperate arrays
    for i in 0..<snapsPerStory {
      let pvIndicator = IGSnapProgressIndicatorView()
      pvIndicator.translatesAutoresizingMaskIntoConstraints = false
      getProgressView.addSubview(applyProperties(pvIndicator, with: i+progressIndicatorViewTag, alpha:0.2))
      pvIndicatorArray.append(pvIndicator)

      let pv = IGSnapProgressView()
      pv.translatesAutoresizingMaskIntoConstraints = false
      pvIndicator.addSubview(applyProperties(pv))
      pvArray.append(pv)
    }

    // Setting Constraints for all progressView indicators
    for index in 0..<pvIndicatorArray.count {
      let pvIndicator = pvIndicatorArray[index]
      if index == 0 {
        pvIndicator.leftConstraiant = pvIndicator.igLeftAnchor.constraint(equalTo: self.getProgressView.igLeftAnchor, constant: padding)
        NSLayoutConstraint.activate([
          pvIndicator.leftConstraiant!,
          pvIndicator.igCenterYAnchor.constraint(equalTo: self.getProgressView.igCenterYAnchor),
          pvIndicator.heightAnchor.constraint(equalToConstant: height)
        ])
        if pvIndicatorArray.count == 1 {
          pvIndicator.rightConstraiant = self.getProgressView.igRightAnchor.constraint(equalTo: pvIndicator.igRightAnchor, constant: padding)
          pvIndicator.rightConstraiant!.isActive = true
        }
      } else {
        let prePVIndicator = pvIndicatorArray[index - 1]
        pvIndicator.widthConstraint = pvIndicator.widthAnchor.constraint(equalTo: prePVIndicator.widthAnchor, multiplier: 1.0)
        pvIndicator.leftConstraiant = pvIndicator.igLeftAnchor.constraint(equalTo: prePVIndicator.igRightAnchor, constant: padding)
        NSLayoutConstraint.activate([
          pvIndicator.leftConstraiant!,
          pvIndicator.igCenterYAnchor.constraint(equalTo: prePVIndicator.igCenterYAnchor),
          pvIndicator.heightAnchor.constraint(equalToConstant: height),
          pvIndicator.widthConstraint!
        ])
        if index == pvIndicatorArray.count - 1 {
          pvIndicator.rightConstraiant = self.igRightAnchor.constraint(equalTo: pvIndicator.igRightAnchor, constant: padding)
          pvIndicator.rightConstraiant!.isActive = true
        }
      }
    }

    // Setting Constraints for all progressViews
    for index in 0..<pvArray.count {
      let pv = pvArray[index]
      let pvIndicator = pvIndicatorArray[index]
      pv.widthConstraint = pv.widthAnchor.constraint(equalToConstant: 0)
      NSLayoutConstraint.activate([
        pv.igLeftAnchor.constraint(equalTo: pvIndicator.igLeftAnchor),
        pv.heightAnchor.constraint(equalTo: pvIndicator.heightAnchor),
        pv.igTopAnchor.constraint(equalTo: pvIndicator.igTopAnchor),
        pv.widthConstraint!
      ])
    }
  }
}
