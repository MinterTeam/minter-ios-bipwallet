//
//  IGStoryPreviewCell.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit
import AVKit
import RxSwift

protocol StoryPreviewProtocol: class {
  func didCompletePreview()
  func moveToPreviousStory()
  func didTapCloseButton()
  func didTapShareButton()
  func didTapSeeMore()
}

enum SnapMovementDirectionState {
  case forward
  case backward
}

//Identifiers
fileprivate let snapViewTagIndicator: Int = 15

final class IGStoryPreviewCell: UICollectionViewCell, UIScrollViewDelegate {

  private let disposeBag = DisposeBag()

  // MARK: - Delegate

  public weak var delegate: StoryPreviewProtocol? {
    didSet { storyHeaderView.delegate = self }
  }

  // MARK: - Private iVars

  private lazy var storyHeaderView: IGStoryPreviewHeaderView = {
    let v = IGStoryPreviewHeaderView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private lazy var storyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    let v = UIButton()
    v.rx.tap.subscribe({ [weak self] (_) in
      self?.delegate?.didTapSeeMore()
    }).disposed(by: disposeBag)

    v.translatesAutoresizingMaskIntoConstraints = false
    v.setImage(UIImage(named: "ig_seeAll"), for: .normal)
    v.titleLabel?.font = UIFont.semiBoldFont(of: 17.0)
    view.addSubview(v)

    let label = UILabel(frame: .init(x: 0, y: 0, width: 100, height: 17))
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "See More"
    label.font = UIFont.semiBoldFont(of: 17.0)
    label.textColor = .white
    view.addSubview(label)

    view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(40)]", options: [.alignAllCenterX], metrics: nil, views: ["view": v]))
    view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[label(80)]", options: [.alignAllCenterX], metrics: nil, views: ["label": label]))
    view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view(40)]-(8)-[label(17)]", options: [.alignAllCenterX],
                                                       metrics: nil,
                                                       views: ["view": v, "label": label]))

    view.addConstraint(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
    view.addConstraint(NSLayoutConstraint(item: v, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))

    return view
  }()

  private lazy var storyTitleView: IGStoryTitleTextView = {
    let view = IGStoryTitleTextView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var longPress_gesture: UILongPressGestureRecognizer = {
    let lp = UILongPressGestureRecognizer.init(target: self, action: #selector(didLongPress(_:)))
    lp.minimumPressDuration = 0.2
    lp.delegate = self
    return lp
  }()

  private lazy var tap_gesture: UITapGestureRecognizer = {
    let tg = UITapGestureRecognizer(target: self, action: #selector(didTapSnap(_:)))
    tg.cancelsTouchesInView = false;
    tg.numberOfTapsRequired = 1
    tg.delegate = self
    return tg
  }()

  private var previousSnapIndex: Int {
    return snapIndex - 1
  }

  private var snapViewXPos: CGFloat {
    return (snapIndex == 0) ? 0 : scrollview.subviews[previousSnapIndex].frame.maxX
  }

  private var videoSnapIndex: Int = 0
  private var handpickedSnapIndex: Int = 0
  var retryBtn: IGRetryLoaderButton!
  var longPressGestureState: UILongPressGestureRecognizer.State?

  // MARK:- Public iVars

  public var direction: SnapMovementDirectionState = .forward

  public let scrollview: UIScrollView = {
    let sv = UIScrollView()
    sv.showsVerticalScrollIndicator = false
    sv.showsHorizontalScrollIndicator = false
    sv.isScrollEnabled = false
    sv.translatesAutoresizingMaskIntoConstraints = false
    return sv
  }()

  public var getSnapIndex: Int {
    return snapIndex
  }

  public var snapIndex: Int = 0 {
    didSet {
      scrollview.isUserInteractionEnabled = true

      if let snap = story?.snaps[safe: snapIndex] {
        let hasURL = URL(string: snap.url) != nil
        storyHeaderView.showShare = hasURL
        storyTitleView.titleLabel.text = String(htmlString: snap.title)
        storyTitleView.textLabel.text = String(htmlString: snap.text)

        storyBottomViewBottomConstraint.constant = (hasURL ? -16 : 50)
        storyBottomViewBottomConstraint.isActive = true
        storyBottomView.isHidden = !hasURL
      }

      switch direction {
      case .forward, .backward:
        guard let snap = story?.snaps[safe: snapIndex] else { return }

        if snap.kind != MimeType.video {

          if let snapView = getSnapview() {
            startRequest(snapView: snapView, with: snap.file)
          } else {
            let snapView = createSnapView()
            startRequest(snapView: snapView, with: snap.file)
          }
        } else {
          storyTitleView.titleLabel.text = ""
          storyTitleView.textLabel.text = ""

          if let videoView = getVideoView(with: snapIndex) {
            startPlayer(videoView: videoView, with: snap.file)
          } else {
            let videoView = createVideoView()
            startPlayer(videoView: videoView, with: snap.file)
          }
        }

//      case .backward:
//        guard let snap = story?.snaps[safe: snapIndex] else { return }
//        if snap.kind != MimeType.video {
//          if let snapView = getSnapview() {
//            self.startRequest(snapView: snapView, with: snap.file)
//          }
//        } else {
//          if let videoView = getVideoView(with: snapIndex) {
//            startPlayer(videoView: videoView, with: snap.file)
//          } else {
//            let videoView = self.createVideoView()
//            self.startPlayer(videoView: videoView, with: snap.file)
//          }
//        }
      }
    }
  }

  public var story: IGStory? {
    didSet {
      storyHeaderView.story = story
    }
  }

  // MARK: - Overriden functions

  override init(frame: CGRect) {
    super.init(frame: frame)
    scrollview.frame = bounds
    loadUIElements()
    installLayoutConstraints()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    direction = .forward
    clearScrollViewGarbages()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Private functions

  private func loadUIElements() {
    scrollview.delegate = self
    scrollview.isPagingEnabled = true
    scrollview.backgroundColor = .black
    contentView.addSubview(scrollview)
    contentView.addSubview(storyHeaderView)
    contentView.addSubview(storyBottomView)
    contentView.addSubview(storyTitleView)
    scrollview.addGestureRecognizer(longPress_gesture)
    scrollview.addGestureRecognizer(tap_gesture)
  }

  lazy var storyBottomViewBottomConstraint = self.storyBottomView.igBottomAnchor.constraint(equalTo: self.contentView.igBottomAnchor, constant: 16.0)

  private func installLayoutConstraints() {
    //Setting constraints for scrollview
    NSLayoutConstraint.activate([
      scrollview.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
      contentView.igRightAnchor.constraint(equalTo: scrollview.igRightAnchor),
      scrollview.igTopAnchor.constraint(equalTo: contentView.igTopAnchor),
      contentView.igBottomAnchor.constraint(equalTo: scrollview.igBottomAnchor),
      scrollview.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0),
      scrollview.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1.0),
    ])

    storyBottomView.addConstraint(NSLayoutConstraint(item: storyBottomView,
                                                     attribute: .height,
                                                     relatedBy: .equal,
                                                     toItem: nil,
                                                     attribute: .height,
                                                     multiplier: 1.0,
                                                     constant: 65.0))

    storyBottomView.addConstraint(NSLayoutConstraint(item: storyBottomView,
                                                     attribute: .width,
                                                     relatedBy: .equal,
                                                     toItem: nil,
                                                     attribute: .width,
                                                     multiplier: 1.0,
                                                     constant: 100.0))
    
    let windowInsets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero

    NSLayoutConstraint.activate([
      storyHeaderView.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
      contentView.igRightAnchor.constraint(equalTo: storyHeaderView.igRightAnchor),
      storyHeaderView.igTopAnchor.constraint(equalTo: contentView.igTopAnchor, constant: windowInsets.top),
      storyHeaderView.heightAnchor.constraint(equalToConstant: 80),
      storyBottomView.igCenterXAnchor.constraint(equalTo: contentView.igCenterXAnchor),
      storyBottomViewBottomConstraint,
      storyTitleView.igBottomAnchor.constraint(equalTo: storyBottomView.igTopAnchor, constant: -25),
      storyTitleView.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
      storyTitleView.igRightAnchor.constraint(equalTo: contentView.igRightAnchor)
    ])
  }

  private func createSnapView() -> UIImageView {
    let snapView = UIImageView()
    snapView.translatesAutoresizingMaskIntoConstraints = false
    snapView.tag = snapIndex + snapViewTagIndicator
    snapView.contentMode = .scaleAspectFill

    let gradient = CAGradientLayer()
    gradient.frame = self.bounds
    gradient.contents = snapView.image?.cgImage
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
    gradient.startPoint = CGPoint(x: 0.5, y: 0)
    gradient.endPoint = CGPoint(x: 0.5, y: 5.0)
    snapView.layer.addSublayer(gradient)

    /**
     Delete if there is any snapview/videoview already present in that frame location. Because of snap delete functionality, snapview/videoview can occupy different frames(created in 2nd position(frame), when 1st postion snap gets deleted, it will move to first position) which leads to weird issues.
     - If only snapViews are there, it will not create any issues.
     - But if story contains both image and video snaps, there will be a chance in same position both snapView and videoView gets created.
     - That's why we need to remove if any snap exists on the same position.
     */
    scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first?.removeFromSuperview()

    scrollview.addSubview(snapView)

    /// Setting constraints for snap view.
    NSLayoutConstraint.activate([
      snapView.leadingAnchor.constraint(equalTo: (snapIndex == 0) ? scrollview.leadingAnchor : scrollview.subviews[previousSnapIndex].trailingAnchor),
      snapView.igTopAnchor.constraint(equalTo: scrollview.igTopAnchor),
      snapView.widthAnchor.constraint(equalTo: scrollview.widthAnchor),
      snapView.heightAnchor.constraint(equalTo: scrollview.heightAnchor),
      scrollview.igBottomAnchor.constraint(equalTo: snapView.igBottomAnchor)
    ])
    if (snapIndex != 0) {
      NSLayoutConstraint.activate([
        snapView.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor, constant: CGFloat(snapIndex)*scrollview.igWidth)
      ])
    }
    return snapView
  }

  private func getSnapview() -> UIImageView? {
    if let imageView = scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first as? UIImageView {
      return imageView
    }
    return nil
  }

  private func createVideoView() -> IGPlayerView {
    let videoView = IGPlayerView()
    videoView.translatesAutoresizingMaskIntoConstraints = false
    videoView.tag = snapIndex + snapViewTagIndicator
    videoView.playerObserverDelegate = self

    /**
     Delete if there is any snapview/videoview already present in that frame location. Because of snap delete functionality, snapview/videoview can occupy different frames(created in 2nd position(frame), when 1st postion snap gets deleted, it will move to first position) which leads to weird issues.
     - If only snapViews are there, it will not create any issues.
     - But if story contains both image and video snaps, there will be a chance in same position both snapView and videoView gets created.
     - That's why we need to remove if any snap exists on the same position.
     */
    scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first?.removeFromSuperview()

    scrollview.addSubview(videoView)
    NSLayoutConstraint.activate([
      videoView.leadingAnchor.constraint(equalTo: (snapIndex == 0) ? scrollview.leadingAnchor : scrollview.subviews[previousSnapIndex].trailingAnchor),
      videoView.igTopAnchor.constraint(equalTo: scrollview.igTopAnchor),
      videoView.widthAnchor.constraint(equalTo: scrollview.widthAnchor),
      videoView.heightAnchor.constraint(equalTo: scrollview.heightAnchor),
      scrollview.igBottomAnchor.constraint(equalTo: videoView.igBottomAnchor)
    ])
    if (snapIndex != 0) {
      NSLayoutConstraint.activate([
        videoView.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor, constant: CGFloat(snapIndex)*scrollview.igWidth),
      ])
    }
    return videoView
  }

  private func getVideoView(with index: Int) -> IGPlayerView? {
    if let videoView = scrollview.subviews.filter({$0.tag == index + snapViewTagIndicator}).first as? IGPlayerView {
      return videoView
    }
    return nil
  }

  private func startRequest(snapView: UIImageView, with url: String) {
    print("startRequest \(url)")

    snapView.setImage(url: url, style: .squared) { result in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        guard let strongSelf = self else { return }

        switch result {
          case .success(_):
            /// Start progressor only if handpickedSnapIndex matches with snapIndex and the requested image url should be matched with current snapIndex imageurl
            if (/*strongSelf.handpickedSnapIndex == strongSelf.snapIndex && */url == strongSelf.story!.snaps[strongSelf.snapIndex].file) {
              strongSelf.startProgressors()
              print("strongSelf.startProgressors()")
            } else {
              print(strongSelf.handpickedSnapIndex)
              print("!=")
              print(strongSelf.snapIndex)
            }
          case .failure(_):
            strongSelf.showRetryButton(with: url, for: snapView)
        }
      }
    }
  }

  private func showRetryButton(with url: String, for snapView: UIImageView) {
    self.retryBtn = IGRetryLoaderButton.init(withURL: url)
    self.retryBtn.translatesAutoresizingMaskIntoConstraints = false
    self.retryBtn.delegate = self
    self.isUserInteractionEnabled = true
    snapView.addSubview(self.retryBtn)
    NSLayoutConstraint.activate([
      self.retryBtn.igCenterXAnchor.constraint(equalTo: snapView.igCenterXAnchor),
      self.retryBtn.igCenterYAnchor.constraint(equalTo: snapView.igCenterYAnchor)
    ])
  }

  private func startPlayer(videoView: IGPlayerView, with url: String) {

    guard scrollview.subviews.count > 0 else { return }

    if story?.isCompletelyVisible == true {
      videoView.startAnimating()
      IGVideoCacheManager.shared.getFile(for: url) { [weak self] (result) in
        guard let strongSelf = self else { return }
        switch result {
          case .success(let videoURL):
            /// Start progressor only if handpickedSnapIndex matches with snapIndex
            if (strongSelf.handpickedSnapIndex == strongSelf.snapIndex) {
              let videoResource = VideoResource(filePath: videoURL.absoluteString)
              videoView.play(with: videoResource)
            }
          case .failure(let error):
            videoView.stopAnimating()
            debugPrint("Video error: \(error)")
        }
      }
    }
  }

  @objc private func didLongPress(_ sender: UILongPressGestureRecognizer) {
    longPressGestureState = sender.state
    if sender.state == .began || sender.state == .ended {
      if (sender.state == .began) {
        pauseEntireSnap()
      } else {
        resumeEntireSnap()
      }
    }
  }

  @objc private func didTapSnap(_ sender: UITapGestureRecognizer) {
    let touchLocation = sender.location(ofTouch: 0, in: self.scrollview)

    if let snapCount = story?.snapsCount {
      var n = snapIndex
      /*!
       * Based on the tap gesture(X) setting the direction to either forward or backward
       */
      if let snap = story?.snaps[n], snap.kind == .image, getSnapview()?.image == nil {
        //Remove retry button if tap forward or backward if it exists
        if let snapView = getSnapview(), let btn = retryBtn, snapView.subviews.contains(btn) {
          snapView.removeRetryButton()
        }
        fillupLastPlayedSnap(n)
      } else {
        //Remove retry button if tap forward or backward if it exists
        if let videoView = getVideoView(with: n), let btn = retryBtn, videoView.subviews.contains(btn) {
          videoView.removeRetryButton()
        }
        if getVideoView(with: n)?.player?.timeControlStatus != .playing {
          fillupLastPlayedSnap(n)
        }
      }

      if touchLocation.x < scrollview.contentOffset.x + (scrollview.frame.width/2) {
        direction = .backward
        if snapIndex >= 1 && snapIndex <= snapCount {
          clearLastPlayedSnaps(n)
          stopSnapProgressors(with: n)
          n -= 1
          resetSnapProgressors(with: n)
          willMoveToPreviousOrNextSnap(n: n)
        } else {
          delegate?.moveToPreviousStory()
        }
      } else {
        if snapIndex >= 0 && snapIndex <= snapCount {
          //Stopping the current running progressors
          stopSnapProgressors(with: n)
          direction = .forward
          n += 1
          willMoveToPreviousOrNextSnap(n: n)
        }
      }
    }
  }

  @objc private func didEnterForeground() {
    if let snap = story?.snaps[snapIndex] {
      if snap.kind == .video {
        let videoView = getVideoView(with: snapIndex)
        startPlayer(videoView: videoView!, with: snap.file)
      } else {
        startSnapProgress(with: snapIndex)
      }
    }
  }

  @objc private func didEnterBackground() {
    if let snap = story?.snaps[snapIndex] {
      if snap.kind == .video {
        stopPlayer()
      }
    }
    resetSnapProgressors(with: snapIndex)
  }

  private func willMoveToPreviousOrNextSnap(n: Int) {
    if let count = story?.snapsCount {
      if n < count {
        //Move to next or previous snap based on index n
        let x = n.toFloat * frame.width
        let offset = CGPoint(x: x,y: 0)
        scrollview.setContentOffset(offset, animated: false)
        story?.lastPlayedSnapIndex = n
        handpickedSnapIndex = n
        snapIndex = n
      } else {
        delegate?.didCompletePreview()
      }
    }
  }

  @objc private func didCompleteProgress() {
    let n = snapIndex + 1
    if let count = story?.snapsCount {
      if n < count {
        //Move to next snap
        let x = n.toFloat * frame.width
        let offset = CGPoint(x: x,y: 0)
        scrollview.setContentOffset(offset, animated: false)
        story?.lastPlayedSnapIndex = n
        direction = .forward
        handpickedSnapIndex = n
        snapIndex = n
      } else {
        stopPlayer()
        delegate?.didCompletePreview()
      }
    }
  }

  private func fillUpMissingImageViews(_ sIndex: Int) {
    if sIndex != 0 {
      for i in 0..<sIndex {
        snapIndex = i
      }
      let xValue = sIndex.toFloat * scrollview.frame.width
      scrollview.contentOffset = CGPoint(x: xValue, y: 0)
    }
  }

  //Before progress view starts we have to fill the progressView
  private func fillupLastPlayedSnap(_ sIndex: Int) {
    if let snap = story?.snaps[sIndex], snap.kind == .video {
      videoSnapIndex = sIndex
      stopPlayer()
    }
    if let holderView = self.getProgressIndicatorView(with: sIndex),
      let progressView = self.getProgressView(with: sIndex){
      progressView.widthConstraint?.isActive = false
      progressView.widthConstraint = progressView.widthAnchor.constraint(equalTo: holderView.widthAnchor, multiplier: 1.0)
      progressView.widthConstraint?.isActive = true
    }
  }

  private func fillupLastPlayedSnaps(_ sIndex: Int) {
    //Coz, we are ignoring the first.snap
    if sIndex != 0 {
      for i in 0..<sIndex {
        if let holderView = self.getProgressIndicatorView(with: i),
          let progressView = self.getProgressView(with: i){
          progressView.widthConstraint?.isActive = false
          progressView.widthConstraint = progressView.widthAnchor.constraint(equalTo: holderView.widthAnchor, multiplier: 1.0)
          progressView.widthConstraint?.isActive = true
        }
      }
    }
  }

  private func clearLastPlayedSnaps(_ sIndex: Int) {
    if let _ = self.getProgressIndicatorView(with: sIndex),
      let progressView = self.getProgressView(with: sIndex) {
      progressView.widthConstraint?.isActive = false
      progressView.widthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
      progressView.widthConstraint?.isActive = true
    }
  }

  private func clearScrollViewGarbages() {
    scrollview.contentOffset = CGPoint(x: 0, y: 0)
    if scrollview.subviews.count > 0 {
      var i = 0 + snapViewTagIndicator
      var snapViews = [UIView]()
      scrollview.subviews.forEach({ (imageView) in
        if imageView.tag == i {
          snapViews.append(imageView)
          i += 1
        }
      })
      if snapViews.count > 0 {
        snapViews.forEach({ (view) in
          view.removeFromSuperview()
        })
      }
    }
  }

  private func gearupTheProgressors(type: MimeType, playerView: IGPlayerView? = nil) {
    print("gearupTheProgressors *****", snapIndex)

    if let holderView = getProgressIndicatorView(with: snapIndex),
      let progressView = getProgressView(with: snapIndex) {

      progressView.story_identifier = "\(self.story?.internalIdentifier ?? 0)"
      progressView.snapIndex = snapIndex
      DispatchQueue.main.async {
        if type == .image {
          progressView.start(with: 5.0, holderView: holderView, completion: { (identifier, snapIndex, isCancelledAbruptly) in
            guard identifier != "Unknown" else {
              return
            }

            print("Completed snapindex: \(snapIndex)")

            print(identifier)

            if isCancelledAbruptly == false {
              self.didCompleteProgress()
            }
          })
        } else {
          //Handled in delegate methods for videos
        }
      }
    }
  }

  // MARK: - Internal functions

  func startProgressors() {
    
    print("startProgressors")
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      print("startProgressors-1")
      guard self.scrollview.subviews.count > 0 else { return }
      print("startProgressors-2")
      let imageView = self.scrollview.subviews.filter { v in v.tag == self.snapIndex + snapViewTagIndicator }.first as? UIImageView
      if imageView?.image != nil && self.story?.isCompletelyVisible == true {
        print("startProgressors-2-1")
        self.gearupTheProgressors(type: .image)
      } else {
        print("startProgressors-2-2")
        // Didend displaying will call this startProgressors method. After that only isCompletelyVisible get true. Then we have to start the video if that snap contains video.
        if self.story?.isCompletelyVisible == true {
          print("startProgressors-2-3")
          let videoView = self.scrollview.subviews.filter { v in v.tag == self.snapIndex + snapViewTagIndicator }.first as? IGPlayerView
          let snap = self.story?.snaps[self.snapIndex]
          if let vv = videoView, self.story?.isCompletelyVisible == true {
            print("startProgressors-2-4")
            self.startPlayer(videoView: vv, with: snap!.file)
          } else {
            print("startProgressors-2-5")
          }
        } else {
          //What a hack, retry this in case UI isn't ready yet
          print("startProgressors-3")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startProgressors()
          }
        }
      }
    }
  }

  func getProgressView(with index: Int) -> IGSnapProgressView? {
    let progressView = storyHeaderView.getProgressView
    if progressView.subviews.count > 0 {
      let pv = getProgressIndicatorView(with: index)?.subviews.first as? IGSnapProgressView
      guard let currentStory = self.story else {
        fatalError("story not found")
      }
      pv?.story = currentStory
      return pv
    }
    return nil
  }

  func getProgressIndicatorView(with index: Int) -> IGSnapProgressIndicatorView? {
    let progressView = storyHeaderView.getProgressView
    return progressView.subviews.filter({ v in v.tag == index+progressIndicatorViewTag }).first as? IGSnapProgressIndicatorView ?? nil
  }

  func adjustPreviousSnapProgressorsWidth(with index: Int) {
    fillupLastPlayedSnaps(index)
  }

  // MARK: - Public functions

  public func willDisplayCellForZerothIndex(with sIndex: Int, handpickedSnapIndex: Int) {
    self.handpickedSnapIndex = handpickedSnapIndex
    story?.isCompletelyVisible = true
    willDisplayCell(with: handpickedSnapIndex)
  }

  public func willDisplayCell(with sIndex: Int) {
    //Todo: Make sure to move filling part and creating at one place
    //Clear the progressor subviews before the creating new set of progressors.
    storyHeaderView.clearTheProgressorSubviews()
    storyHeaderView.createSnapProgressors()
    fillUpMissingImageViews(sIndex)
    fillupLastPlayedSnaps(sIndex)
    snapIndex = sIndex

    //Remove the previous observors
    NotificationCenter.default.removeObserver(self)

    // Add the observer to handle application from background to foreground
    NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  public func startSnapProgress(with sIndex: Int) {
    if let indicatorView = getProgressIndicatorView(with: sIndex),
      let pv = getProgressView(with: sIndex) {
      pv.start(with: 5.0, holderView: indicatorView, completion: { (identifier, snapIndex, isCancelledAbruptly) in
        if isCancelledAbruptly == false {
          self.didCompleteProgress()
        }
      })
    }
  }

  public func pauseSnapProgressors(with sIndex: Int) {
    story?.isCompletelyVisible = false
    getProgressView(with: sIndex)?.pause()
  }

  public func stopSnapProgressors(with sIndex: Int) {
    getProgressView(with: sIndex)?.stop()
  }

  public func resetSnapProgressors(with sIndex: Int) {
    self.getProgressView(with: sIndex)?.reset()
  }

  public func pausePlayer(with sIndex: Int) {
    getVideoView(with: sIndex)?.pause()
  }

  public func stopPlayer() {
    let videoView = getVideoView(with: videoSnapIndex)
    if videoView?.player?.timeControlStatus != .playing {
      getVideoView(with: videoSnapIndex)?.player?.replaceCurrentItem(with: nil)
    }
    videoView?.stop()
    //getVideoView(with: videoSnapIndex)?.player = nil
  }

  public func resumePlayer(with sIndex: Int) {
    getVideoView(with: sIndex)?.play()
  }

  public func didEndDisplayingCell() {
      
  }

  public func resumePreviousSnapProgress(with sIndex: Int) {
    getProgressView(with: sIndex)?.resume()
  }

  public func pauseEntireSnap() {
    let v = getProgressView(with: snapIndex)
    let videoView = scrollview.subviews.filter { v in v.tag == snapIndex + snapViewTagIndicator }.first as? IGPlayerView
    if videoView != nil {
      v?.pause()
      videoView?.pause()
    } else {
      v?.pause()
    }
  }

  public func resumeEntireSnap() {
    let v = getProgressView(with: snapIndex)
    let videoView = scrollview.subviews.filter { v in v.tag == snapIndex + snapViewTagIndicator }.first as? IGPlayerView
    if videoView != nil {
      v?.resume()
      videoView?.play()
    } else {
      v?.resume()
    }
  }

  //Used the below function for image retry option
  public func retryRequest(view: UIView, with url: String) {
    if let v = view as? UIImageView {
      v.removeRetryButton()
      self.startRequest(snapView: v, with: url)
    } else if let v = view as? IGPlayerView {
      v.removeRetryButton()
      self.startPlayer(videoView: v, with: url)
    }
  }
}

// MARK: - Extension|StoryPreviewHeaderProtocol

extension IGStoryPreviewCell: StoryPreviewHeaderProtocol {

  func didTapShareButton() {
    delegate?.didTapShareButton()
  }

  func didTapCloseButton() {
    delegate?.didTapCloseButton()
  }
}

// MARK: - Extension|RetryBtnDelegate

extension IGStoryPreviewCell: RetryBtnDelegate {
  func retryButtonTapped() {
    self.retryRequest(view: retryBtn.superview!, with: retryBtn.contentURL!)
  }
}

// MARK: - Extension|IGPlayerObserverDelegate

extension IGStoryPreviewCell: IGPlayerObserver {

  func didStartPlaying() {
    if let videoView = getVideoView(with: snapIndex), videoView.currentTime <= 0 {
      if videoView.error == nil && (story?.isCompletelyVisible)! == true {
        if let holderView = getProgressIndicatorView(with: snapIndex),
          let progressView = getProgressView(with: snapIndex) {
          progressView.story_identifier = "\(self.story?.internalIdentifier ?? 0)"
          progressView.snapIndex = snapIndex
          if let duration = videoView.currentItem?.asset.duration {
            if Float(duration.value) > 0 {
              progressView.start(with: duration.seconds,
                                 holderView: holderView,
                                 completion: { (identifier, snapIndex, isCancelledAbruptly) in
                if isCancelledAbruptly == false {
                  self.videoSnapIndex = snapIndex
                  self.stopPlayer()
                  self.didCompleteProgress()
                } else {
                  self.videoSnapIndex = snapIndex
                  self.stopPlayer()
                }
              })
            } else {
              debugPrint("Player error: Unable to play the video")
            }
          }
        }
      }
    }
  }

  func didFailed(withError error: String, for url: URL?) {
    debugPrint("Failed with error: \(error)")
    if let videoView = getVideoView(with: snapIndex), let videoURL = url {
      self.retryBtn = IGRetryLoaderButton(withURL: videoURL.absoluteString)
      self.retryBtn.translatesAutoresizingMaskIntoConstraints = false
      self.retryBtn.delegate = self
      self.isUserInteractionEnabled = true
      videoView.addSubview(self.retryBtn)
      NSLayoutConstraint.activate([
        self.retryBtn.igCenterXAnchor.constraint(equalTo: videoView.igCenterXAnchor),
        self.retryBtn.igCenterYAnchor.constraint(equalTo: videoView.igCenterYAnchor)
      ])
    }
  }

  func didCompletePlay() {
    //Video completed
  }

  func didTrack(progress: Float) {
    //Delegate already handled. If we just print progress, it will print the player current running time
  }
}

extension IGStoryPreviewCell: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if (gestureRecognizer is UISwipeGestureRecognizer) {
      return true
    }
    return false
  }
}

class IGStoryTitleTextView: UIView {

  var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.semiBoldFont(of: 24)
    label.numberOfLines = 0
    label.textColor = .white
    return label
  }()

  var textLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.defaultFont(of: 18)
    label.numberOfLines = 0
    label.textColor = .white
    return label
  }()

  // MARK: -

  override init(frame: CGRect) {
    super.init(frame: frame)

    loadUIElements()
    installLayoutConstraints()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: -

  func loadUIElements() {
    addSubview(titleLabel)
    addSubview(textLabel)
  }

  func installLayoutConstraints() {
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-24-[titleLabel]-24-|", options: [], metrics: nil, views: ["titleLabel": titleLabel]))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-24-[textLabel]-24-|", options: [], metrics: nil, views: ["textLabel": textLabel]))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[titleLabel]-8-[textLabel]-0-|", options: [], metrics: nil, views: ["titleLabel": titleLabel, "textLabel": textLabel]))
  }

}
