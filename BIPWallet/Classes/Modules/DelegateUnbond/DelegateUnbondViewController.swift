//
//  DelegateUnbondViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 16/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture
import RxBiBinding

class DelegateUnbondViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: - IBOutlet

  var isDragging = false

  @IBOutlet weak var mainView: HandlerVerticalSnapDraggableView!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var validatorView: DashedView!
  @IBOutlet weak var validatorTextField: ValidatorTextField!
  @IBOutlet weak var validatorTitle: UILabel!
  @IBOutlet weak var validatorPublicKey: UILabel!
  @IBOutlet weak var coinTextField: DefaultTextField! {
    didSet {
      coinTextField.delegate = self
    }
  }
  @IBOutlet weak var amountTextField: ValidatableTextField!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var useMaxButton: UIButton!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!
  @IBOutlet weak var multipleWalletsImage: UIImageView!
  @IBOutlet weak var clearValidatorButton: UIButton!
  @IBOutlet weak var coinTitle: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = DelegateUnbondViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: DelegateUnbondViewModel) {
    configureDefault()

    //Output
    viewModel.output.disableValidatorChange.asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (disable) in
        if disable {
          self?.validatorView.backgroundColor = .mainWhiteColor()
          self?.validatorView.showDashedBorder = true
          self?.clearValidatorButton.isHidden = true
        } else {
          self?.validatorView.showDashedBorder = false
          self?.clearValidatorButton.isHidden = false
        }
      }).disposed(by: disposeBag)

    viewModel.output.hasMultipleCoins.asDriver(onErrorJustReturn: false)
      .map {!$0}.drive(multipleWalletsImage.rx.isHidden)
      .disposed(by: disposeBag)

    viewModel.output.fee.asDriver(onErrorJustReturn: "")
      .drive(feeLabel.rx.text).disposed(by: disposeBag)

    viewModel.output.showInput.subscribe(onNext: { [weak self] data in
      self?.validatorView.alpha = 0.0
      self?.validatorTextField.alpha = 1.0
      self?.validatorTextField.text = ""
      self?.validatorTextField.becomeFirstResponder()
    }).disposed(by: disposeBag)

    viewModel.output.showCoins.subscribe(onNext: { [weak self] data in
      self?.showPicker(data: data) { selected in
        self?.viewModel.input.didSelectCoin.onNext(selected)
      }
      self?.amountTextField.endEditing(true)
      self?.validatorTextField.endEditing(true)
    }).disposed(by: disposeBag)

    viewModel.output.autocompleteValidatorsItems.asDriver(onErrorJustReturn: [])
      .drive(onNext: { [weak self] (items) in
        self?.validatorTextField.filterItems(items)
      }).disposed(by: disposeBag)

    viewModel.output.title.asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] val in
        self?.mainView.title = val
      }).disposed(by: disposeBag)

    viewModel.output.isButtonEnabled.asDriver(onErrorJustReturn: false)
      .drive(sendButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.output.errorMessage.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] (message) in
      BannerHelper.performErrorNotification(title: message, subtitle: nil)
      self?.hardImpactFeedbackGenerator.prepare()
      self?.hardImpactFeedbackGenerator.impactOccurred()
    }).disposed(by: disposeBag)

    viewModel.output.validatorPublicKey.asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] val in
        self?.validatorPublicKey.text = val
        self?.validatorView.alpha = 1.0
        self?.validatorTextField.alpha = 0.0
        self?.validatorTextField.resignFirstResponder()
      }).disposed(by: disposeBag)

    viewModel.output.validatorName.asDriver(onErrorJustReturn: "")
      .drive(validatorTitle.rx.text).disposed(by: disposeBag)

    viewModel.output.description.asDriver(onErrorJustReturn: nil)
      .drive(descriptionLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel.output.coinTitle.asDriver(onErrorJustReturn: nil)
      .drive(coinTitle.rx.text)
      .disposed(by: disposeBag)

    //Input
    (validatorTextField.rx.text <-> viewModel.input.validator).disposed(by: disposeBag)

    Observable.of(validatorTextField.rx.controlEvent(.editingDidEnd).map{_ in},
                  validatorTextField.rx.controlEvent(.editingDidEndOnExit).map{_ in})
      .merge().asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.didEndEditingValidator).disposed(by: disposeBag)

    validatorTextField.rightView?.rx.tapGesture().when(.ended)
      .map{_ in}.asDriver(onErrorJustReturn: ())
      .drive(viewModel.input.didTapShowValidators)
      .disposed(by: disposeBag)

    validatorTextField.itemSelectionHandler = { [weak self] items, index in
      if let item = items[safe: index] {
        self?.viewModel.input.didSelectAutocompleteItem.onNext(item)
      }
    }

    clearValidatorButton.rx.tap.map {_ in Void() }
      .subscribe(viewModel.input.didTapClear)
      .disposed(by: disposeBag)

    coinTextField.rx.tapGesture().when(.ended).map {_ in Void() }
      .subscribe(viewModel.input.didTapCoin)
      .disposed(by: disposeBag)

    (amountTextField.rx.text <-> viewModel.input.amount).disposed(by: disposeBag)
    (coinTextField.rx.text <-> viewModel.input.coin).disposed(by: disposeBag)

    let buttonTap = sendButton.rx.tap.asDriver()
    buttonTap.drive(viewModel.input.didTapSend).disposed(by: disposeBag)
    buttonTap.drive(onNext: { [weak self] (_) in
      self?.amountTextField.resignFirstResponder()
      self?.validatorTextField.resignFirstResponder()
    }).disposed(by: disposeBag)

    useMaxButton.rx.tap.asDriver()
      .drive(viewModel.input.didTapUseMax)
      .disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    mainView?.delegate = self

    amountTextField.rightPadding = CGFloat(self.useMaxButton.bounds.width)

    Observable<Notification>.merge(NotificationCenter.default.rx.notification(ViewController.keyboardWillShowNotification),
                                   NotificationCenter.default.rx.notification(ViewController.keyboardWillHideNotification))
      .subscribe(onNext: { [weak self] (not) in
        guard let `self` = self else { return }
        guard let keyboardSize = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        let keyboardHeight = keyboardFrame.height

        var bottomPadding = self.view.bounds.height - (self.view.bounds.height - keyboardHeight) + 8.0

        if ViewController.keyboardWillHideNotification == not.name {
          bottomPadding = 34
        }

        //Some magic numbers to make field visible
        if self.view.bounds.height < 600 {
          if self.validatorTextField.isFirstResponder {
            bottomPadding -= 80
          } else if self.amountTextField.isFirstResponder {
            bottomPadding -= 30
          }
        }

        self.bottomConstraint?.constant = bottomPadding

        if !self.isDragging {

          UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
          }
        }
      }).disposed(by: disposeBag)

    Observable.merge(validatorView.rx.tapGesture().when(.ended), coinTextField.rx.tapGesture().when(.ended))
      .subscribe(onNext: { [weak self] (_) in
        self?.amountTextField.endEditing(true)
      }).disposed(by: disposeBag)

    configure(with: viewModel)
  }

  override func loadView() {
    super.loadView()

    mainView.title = "Delegate".localized()

    showBlurOverview { [weak self] in
      UIView.animate(withDuration: 0.5) {
        self?.updateBlurView(percentage: 0.0)
      }
      self?.dismiss(animated: true) {}
    }
  }

  func showPicker(data: [[String]], completion: (([Int: String]) -> ())?) {
    let picker = McPicker(data: data)
    picker.toolbarButtonsColor = .white
    picker.toolbarDoneButtonColor = .white
    picker.toolbarBarTintColor = UIColor.mainPurpleColor()
    picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
    picker.show { (selected) in
      completion?(selected)
    }
  }

}

extension DelegateUnbondViewController: DraggableViewDelegate {

  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }

    isDragging = true

    if let mainView = targetView as? DraggableViewDelegate {
      mainView.panGestureDidChange?(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)
    }

    let percentage = 1 - translation.y/targetView.bounds.height

    if percentage < 0.8 {
      amountTextField.endEditing(true)
      validatorTextField.endEditing(true)
    }

    updateBlurView(percentage: percentage)
  }

  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint, velocityInView: CGPoint) {
    guard let targetView = mainView else {
      return
    }

    isDragging = false

    targetView.panGestureDidEnd(panGesture, originalCenter: originalCenter, translation: translation, velocityInView: velocityInView)

    let percentage = translation.y/targetView.bounds.height

    if percentage >= 0.5 {
      updateBlurView(percentage: 0.0)
      self.dismiss(animated: true) {}
    } else {
      UIView.animate(withDuration: 0.25) {
        self.view.setNeedsLayout()
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
      }
      updateBlurView(percentage: 1.0)
    }
  }
}

extension DelegateUnbondViewController: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return false
  }

}

class ValidatorTextField: SearchTextField {

  var rightPadding = CGFloat(50)
  private let topPadding = CGFloat(10.0)
  private let leftPadding = CGFloat(16.0)
  private let invalidViewWidth = CGFloat(30.0)

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    customize()

    var theme = SearchTextFieldTheme.lightTheme()
    theme.borderWidth = 1.0
    theme.cellHeight = 48.0
    theme.font = UIFont.mediumFont(of: 17.0)
    theme.fontColor = UIColor.mainBlackColor()
    theme.separatorColor = UIColor.separatorColor()

    self.theme = theme
    self.maxNumberOfResults = 3
    self.tableCornerRadius = 8.0
    self.isScrollingEnabled = false
    self.tableYOffset = 8.0
  }

  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: leftPadding,
                  y: topPadding,
                  width: bounds.width - 2*leftPadding - rightPadding,
                  height: bounds.height - 2*topPadding)
  }

  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: leftPadding,
                  y: topPadding,
                  width: bounds.width - 2*leftPadding - rightPadding,
                  height: bounds.height - 2*topPadding)
  }

  override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: bounds.width - invalidViewWidth,
                  y: 0,
                  width: invalidViewWidth,
                  height: bounds.height)
  }

  override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(x: leftPadding,
                  y: 0,
                  width: 0,
                  height: bounds.height)
  }

  // MARK: -

  func customize() {
    addObservers()

    let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
    btn.setImage(UIImage(named: "ValidatorsListIcon"), for: .normal)
    btn.imageEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 8)
    self.rightView = btn
    self.rightViewMode = .always

    self.font = UIFont.mediumFont(of: 17.0)
    self.layer.borderWidth = 0
    self.layer.cornerRadius = 8.0
    self.backgroundColor = UIColor.textFieldBackgroundColor()
  }

  func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(didStartEditing(notification:)), name: UITextField.textDidBeginEditingNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didEndEditing(notification:)), name: UITextField.textDidEndEditingNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func didStartEditing(notification: NSNotification) {
    guard (notification.object as AnyObject?) === self else { return }
    self.backgroundColor = UIColor.activeTextFieldBackgroundColor()
    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 1
  }

  @objc func didEndEditing(notification: NSNotification) {
    guard (notification.object as AnyObject?) === self else { return }
    self.backgroundColor = UIColor.textFieldBackgroundColor()
    self.layer.borderColor = UIColor.textFieldBorderColor().cgColor
    self.layer.borderWidth = 0
  }

}
