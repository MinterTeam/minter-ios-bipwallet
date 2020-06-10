//
//  PINViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 20/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class PINViewController: BaseViewController, Controller, StoryboardInitializable {

  typealias ViewModelType = PINViewModel
  var viewModel: PINViewModel!

  // MARK: -

  func configure(with viewModel: PINViewModel) {
    viewModel.output.title.asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] (title) in
        self?.title = title
    }).disposed(by: disposeBag)

    viewModel.output.desc.asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] (desc) in
        self?.descTitle.text = desc
    }).disposed(by: disposeBag)

    viewModel.output.shakeError.asDriver(onErrorJustReturn: ()).drive(onNext: { _ in
      self.shakeError()
    }).disposed(by: disposeBag)

    self.rx.viewDidAppear.asDriver(onErrorJustReturn: false)
      .drive(viewModel.input.viewDidAppear).disposed(by: disposeBag)
  }

  // MARK: -

  @IBOutlet weak var descTitle: UILabel!
  @IBOutlet weak var pinView: CBPinEntryView! {
    didSet {
      pinView.delegate = self
    }
  }
  @IBOutlet weak var button1: UIButton!
  @IBOutlet weak var button2: UIButton!
  @IBOutlet weak var button3: UIButton!
  @IBOutlet weak var button4: UIButton!
  @IBOutlet weak var button5: UIButton!
  @IBOutlet weak var button6: UIButton!
  @IBOutlet weak var button7: UIButton!
  @IBOutlet weak var button8: UIButton!
  @IBOutlet weak var button9: UIButton!
  @IBOutlet weak var button0: UIButton!
  @IBAction func buttonTap(sender: UIButton) {
    let string = sender.title(for: .normal) ?? ""
    let range = NSRange(location: (pinView.textField.text ?? "").count, length: 1)
    if true == pinView.textField.delegate?.textField?(pinView.textField,
                                                      shouldChangeCharactersIn: range,
                                                      replacementString: string) {
      if #available(iOS 11.0, *) {
        pinView.textField.insertText(string)
      } else {
        pinView.textField.text = (pinView.textField.text ?? "") + string
        pinView.textField.sendActions(for: .editingChanged)
      }
    }
  }
  @IBAction func backspaceTap(_ sender: UIButton) {
    let string = sender.title(for: .normal) ?? ""
    let range = NSRange(location: max(0, (pinView.textField.text ?? "").count-1), length: 1)
    if true == pinView.textField.delegate?.textField?(pinView.textField,
                                                      shouldChangeCharactersIn: range,
                                                      replacementString: string) {
      if #available(iOS 11.0, *) {
        pinView.textField.deleteBackward()
      } else {
        let txt = (pinView.textField.text ?? "")
        pinView.textField.text = String(txt.dropLast())
        pinView.textField.sendActions(for: .editingChanged)
      }
    }
  }

  // MARK: -

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Set PIN-code".localized()

    configure(with: viewModel)

    viewModel.input.viewDidLoad.onNext(())

    pinView.becomeFirstResponder()
    pinView.textField.inputView = button0
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.navigationController?.navigationBar.barTintColor = .mainPurpleColor()
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "NavigationBar"), for: .default)
    self.navigationController?.navigationBar.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.white,
      NSAttributedString.Key.font: UIFont.semiBoldFont(of: 18.0)
    ]
    self.navigationController?.navigationBar.shadowImage = UIImage(named: "PurpleNavigationBarShadowImage")
    self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "BackButtonWhiteIcon")
  }

  func shakeError() {
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: pinView.center.x - 10,
                                                   y: pinView.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: pinView.center.x + 10,
                                                 y: pinView.center.y))
    pinView.layer.add(animation, forKey: "position")

    pinView.clearEntry()

    self.hardImpactFeedbackGenerator.prepare()
    self.hardImpactFeedbackGenerator.impactOccurred()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

}

extension PINViewController: CBPinEntryViewDelegate {

  func entryChanged(_ completed: Bool) {}

  func entryCompleted(with entry: String?) {
    viewModel.input.pin.onNext(entry ?? "")
  }

}
