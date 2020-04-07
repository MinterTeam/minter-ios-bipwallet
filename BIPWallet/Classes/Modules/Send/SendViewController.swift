//
//  SendViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/02/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices
import AVFoundation
import NotificationBannerSwift

class SendViewController: BaseViewController,
  Controller,
  StoryboardInitializable,
  SendPopupViewControllerDelegate,
  SentPopupViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, TextViewTableViewCellDelegate {

  // MARK: - IBOutlet

  let fakeTextField = UITextField()
  @IBOutlet weak var scanQRButton: UIBarButtonItem!
  @IBOutlet weak var txScanButton: UIBarButtonItem!
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      tableView.contentInset = UIEdgeInsets(top: 10.0,
                                            left: 0.0,
                                            bottom: 0.0,
                                            right: 0.0)
      tableView.rowHeight = UITableView.automaticDimension
      tableView.estimatedRowHeight = 70
    }
  }
  @IBOutlet weak var autocompleteViewWrapper: UIView!
  @IBOutlet weak var autocompleteView: LUAutocompleteView! {
    didSet {
      autocompleteView.autocompleteCellNibName = "CoinAutocompleteCell"
    }
  }

  // MARK: -

  var popupViewController: PopupViewController?

  lazy var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
      $0.reader = QRCodeReader(metadataObjectTypes: [.qr],
                               captureDevicePosition: .back)
      $0.showSwitchCameraButton = false
    }
    return QRCodeReaderViewController(builder: builder)
  }()

  // MARK: - ControllerProtocol

  typealias ViewModelType = SendViewModel

  var viewModel: ViewModelType!

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    registerCells()
    configure(with: viewModel)

    autocompleteViewWrapper.frame = .zero
    self.view.addSubview(autocompleteViewWrapper)

    tableView.beginUpdates()
    tableView.endUpdates()
  }

  // MARK: -

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return viewModel.rowsCount(for: section)
  }

  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let item = self.viewModel.cellItem(section: indexPath.section,
                                             row: indexPath.row),
      let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier,
                                               for: indexPath) as? BaseCell else {
      return UITableViewCell()
    }

    cell.configure(item: item)

    if let pickerCell = cell as? PickerTableViewCell {
      pickerCell.dataSource = self
      pickerCell.delegate = self
      pickerCell.updateRightViewMode()
    }

    if let buttonCell = cell as? ButtonTableViewCell {
      buttonCell.delegate = self
    }

    if let textViewCell = cell as? TextViewTableViewCell {
      textViewCell.delegate = self
      autocompleteView.textField = fakeTextField

      textViewCell.textView.rx.didEndEditing.subscribe(onNext: { (_) in
        self.fakeTextField.sendActions(for: .editingDidEnd)
      }).disposed(by: disposeBag)

      textViewCell.textView.rx.didChange.subscribe(onNext: { (_) in
        
      }).disposed(by: disposeBag)

      if nil != textViewCell as? SendPayloadTableViewCell {
        textViewCell.textView?.rx.text
          .subscribe(viewModel.input.payload).disposed(by: self.disposeBag)
      }
    }

    if let textField = cell as? AmountTextFieldTableViewCell {
      textField.amountDelegate = self
    }

    return cell
  }

}

extension SendViewController {

  func configure(with viewModel: SendViewModel) {// swiftlint:disable:this type_body_length cyclomatic_complexity function_body_length
    autocompleteView.dataSource = viewModel
    autocompleteView.delegate = viewModel

    Observable.merge(viewModel.output.recipient, viewModel.output.didProvideAutocomplete.map {_ in return nil })
      .asDriver(onErrorJustReturn: "")
      .drive(onNext: { (val) in
        if val != nil {
          self.fakeTextField.text = val
          self.fakeTextField.sendActions(for: .editingChanged)
        }
        if let usernameCell = self.tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? UsernameTableViewCell {
          let newFrame = self.view.convert(usernameCell.frame, from: self.tableView)
          self.autocompleteViewWrapper.frame = CGRect(x: 22.0,
                                                      y: newFrame.maxY,
                                                      width: usernameCell.textView.bounds.width + 4,
                                                      height: self.autocompleteView.heightConstraint?.constant ?? 0.0)
        }
      }).disposed(by: disposeBag)

    txScanButton
      .rx
      .tap
      .asDriver()
      .drive(viewModel.input.txScanButtonDidTap)
      .disposed(by: disposeBag)

    viewModel.output.errorNotification
      .asDriver(onErrorJustReturn: nil)
      .filter({ (notification) -> Bool in
        return nil != notification
      }).drive(onNext: { (notification) in
        let banner = NotificationBanner(title: notification?.title ?? "",
                                        subtitle: notification?.text,
                                        style: .danger)
        banner.show()
      }).disposed(by: disposeBag)

    viewModel
      .output
      .txErrorNotification
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] (notification) in
        guard nil != notification else {
          return
        }
        self?.popupViewController?.dismiss(animated: true, completion: nil)
        let banner = NotificationBanner(title: notification?.title ?? "",
                                        subtitle: notification?.text,
                                        style: .danger)
        banner.show()
      }).disposed(by: disposeBag)

    viewModel
      .output
      .popup
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] (popup) in
        if popup == nil {
          self?.popupViewController?.dismiss(animated: true, completion: nil)
          return
        }

        if let sent = popup as? SentPopupViewController {
          sent.delegate = self
        }

        if let send = popup as? SendPopupViewController {
          self?.popupViewController = nil
          send.delegate = self
        }

        if self?.popupViewController == nil {
          popup?.modalPresentationStyle = .overCurrentContext
          popup?.modalTransitionStyle = .crossDissolve
          self?.showPopup(viewController: popup!)
          self?.popupViewController = popup
        } else {
          self?.showPopup(viewController: popup!,
                          inPopupViewController: self!.popupViewController)
        }
      }).disposed(by: disposeBag)

    viewModel
      .sections
      .asObservable()
      .subscribe(onNext: { [weak self] (_) in
        self?.tableView.reloadData()
        guard let selectedPickerItem = self?.viewModel.selectedPickerItem() else {
          return
        }
        //Move to cell
        if let balanceCell = self?.tableView
          .cellForRow(at: IndexPath(item: 0, section: 0)) as? PickerTableViewCell {
          balanceCell.selectField.text = selectedPickerItem.title
        }
      }).disposed(by: disposeBag)

    viewModel
      .output
      .showViewController
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] (viewController) in
        guard let viewController = viewController else { return }
        self?.tabBarController?.present(viewController, animated: true, completion: nil)
      }).disposed(by: disposeBag)

    txScanButton
      .rx
      .tap
      .asDriver()
      .drive(viewModel.input.txScanButtonDidTap)
      .disposed(by: disposeBag)

    txScanButton
      .rx
      .tap
      .subscribe({ [weak self] (_) in
        self?.present(self!.readerVC, animated: true, completion: nil)
      }).disposed(by: disposeBag)

    viewModel
      .output
      .openAppSettings
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [weak self] in
//        self?.openAppSpecificSettings()
      }).disposed(by: disposeBag)

    viewModel
      .output
      .updateTableHeight
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [weak self] (_) in
        self?.tableView.beginUpdates()
        self?.tableView.endUpdates()
      }).disposed(by: disposeBag)

    viewModel.output.shouldShowAlert
      .asDriver(onErrorJustReturn: "")
      .drive(onNext: { [weak self] (message) in
        let alert = UIAlertController(title: "❗️❗️ ATTENTION:", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
          
        }))
        self?.present(alert, animated: true, completion: {
          
        })
    }).disposed(by: disposeBag)

    readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
      self?.readerVC.stopScanning()
      self?.readerVC.dismiss(animated: true) {
        if let res = result?.value {
          self?.viewModel.input.didScanQR.onNext(res)
        }
      }
    }
  }
}

extension SendViewController: PickerTableViewCellDelegate {

  func didFinish(with item: PickerTableViewCellPickerItem?) {
    if let item = item?.object as? AccountPickerItem {
      viewModel.accountPickerSelect(item: item)
    }
  }

  func willShowPicker() {
    tableView.endEditing(true)
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsChooseCoinButton)
  }
}

extension SendViewController: PickerTableViewCellDataSource {
  func pickerItems(for cell: PickerTableViewCell) -> [PickerTableViewCellPickerItem] {
    return viewModel.accountPickerItems()
  }
}

extension SendViewController: ButtonTableViewCellDelegate {

  func buttonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
//    SoundHelper.playSoundIfAllowed(type: .bip)
//    hardImpactFeedbackGenerator.prepare()
//    hardImpactFeedbackGenerator.impactOccurred()
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsSendButton)
    tableView.endEditing(true)
  }

  // MARK: - Validation

  func validate(cell: ValidatableCellProtocol) {}
}

extension SendViewController {

  // MARK: - SendPopupViewControllerDelegate

  func didFinish(viewController: SendPopupViewController) {
//    SoundHelper.playSoundIfAllowed(type: .bip)
//    lightImpactFeedbackGenerator.prepare()
//    lightImpactFeedbackGenerator.impactOccurred()
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinPopupSendButton)
    viewModel.submitSendButtonTaped()
  }

  func didCancel(viewController: SendPopupViewController) {
//    SoundHelper.playSoundIfAllowed(type: .cancel)
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinPopupCancelButton)
    viewController.dismiss(animated: true, completion: nil)
  }

  // MARK: - SentPopupViewControllerDelegate

  func didTapActionButton(viewController: SentPopupViewController) {
//    SoundHelper.playSoundIfAllowed(type: .click)
//    hardImpactFeedbackGenerator.prepare()
//    hardImpactFeedbackGenerator.impactOccurred()
//    AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupViewTransactionButton)
    viewController.dismiss(animated: true) { [weak self] in
      if let url = self?.viewModel.lastTransactionExplorerURL() {
//        let vc = BaseSafariViewController(url: url)
//        self?.present(vc, animated: true) {}
      }
    }
  }

  func didTapSecondActionButton(viewController: SentPopupViewController) {
//    SoundHelper.playSoundIfAllowed(type: .click)
//    lightImpactFeedbackGenerator.prepare()
//    lightImpactFeedbackGenerator.impactOccurred()
//    AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupShareTransactionButton)
    viewController.dismiss(animated: true) { [weak self] in
      if let url = self?.viewModel.lastTransactionExplorerURL() {
//        let vc = ActivityRouter.activityViewController(activities: [url], sourceView: self!.view)
//        self?.present(vc, animated: true, completion: nil)
      }
    }
  }

  func didTapSecondButton(viewController: SentPopupViewController) {
//    SoundHelper.playSoundIfAllowed(type: .cancel)
//    lightImpactFeedbackGenerator.prepare()
//    AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupCloseButton)
    viewController.dismiss(animated: true, completion: nil)
  }

  // MARK: -

  func heightDidChange(cell: TextViewTableViewCell) {
    // Disabling animations gives us our desired behaviour
    UIView.setAnimationsEnabled(false)
    /* These will causes table cell heights to be recaluclated,
    without reloading the entire cell */
    tableView.beginUpdates()
    tableView.endUpdates()
    // Re-enable animations
    UIView.setAnimationsEnabled(true)

    if let cell = cell as? SendPayloadTableViewCell {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        let textView = cell.textView
        if let startIndex = textView?.selectedTextRange?.start,
          let caretRect = textView?.caretRect(for: startIndex) {
          let newPosition = cell.textView.convert(caretRect, to: self.tableView).origin
          self.tableView.scrollRectToVisible(CGRect(x: 0,
                                                    y: newPosition.y,
                                                    width: self.tableView.bounds.width,
                                                    height: textView?.bounds.height ?? 0),
                                             animated: true)
        }
      }
    }
  }

  func heightWillChange(cell: TextViewTableViewCell) {}

  func didTapScanButton(cell: UsernameTableViewCell?) {
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsQRButton)
    readerVC.delegate = self
    cell?.textView.becomeFirstResponder()
    readerVC.completionBlock = { (result: QRCodeReaderResult?) in
      if let indexPath = self.tableView.indexPath(for: cell!),
        let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
        cell?.textView.text = result?.value
      }
    }
    // Presents the readerVC as modal form sheet
    readerVC.modalPresentationStyle = .formSheet
    present(readerVC, animated: true, completion: nil)
  }
}

extension SendViewController: ValidatableCellDelegate {

  func didValidateField(field: ValidatableCellProtocol?) {}

  func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {}
}

extension SendViewController: QRCodeReaderViewControllerDelegate {

  // MARK: - QRCodeReaderViewController Delegate Methods

  func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {}

  func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {}

  func readerDidCancel(_ reader: QRCodeReaderViewController) {
//    SoundHelper.playSoundIfAllowed(type: .cancel)
    reader.stopScanning()
    dismiss(animated: true, completion: nil)
  }
}

extension SendViewController: AmountTextFieldTableViewCellDelegate {

  func didTapUseMax() {
    self.view.endEditing(true)
//    AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsUseMaxButton)
  }
}

extension SendViewController {

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SendHeader") as? SendHeader
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if nil != viewModel.sections.value[safe: section]?.header {
      return 24
    }
    return 0.1
  }

  private func registerCells() {
    tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "TextFieldTableViewCell")
    tableView.register(UINib(nibName: "UsernameTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "UsernameTableViewCell")
    tableView.register(UINib(nibName: "PayloadTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "PayloadTableViewCell")
    tableView.register(UINib(nibName: "AmountTextFieldTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "AmountTextFieldTableViewCell")
    tableView.register(UINib(nibName: "AddressTextViewTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "AddressTextViewTableViewCell")
    tableView.register(UINib(nibName: "PickerTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "PickerTableViewCell")
    tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SwitchTableViewCell")
    tableView.register(UINib(nibName: "TwoTitleTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "TwoTitleTableViewCell")
    tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SeparatorTableViewCell")
    tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "ButtonTableViewCell")
    tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "BlankTableViewCell")
    tableView.register(UINib(nibName: "SendPayloadTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "SendPayloadTableViewCell")
    tableView.register(UINib(nibName: "SendHeader", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "SendHeader")
  }
}
