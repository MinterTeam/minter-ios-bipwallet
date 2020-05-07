//
//  GetCoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip

class GetCoinsViewController: ConvertCoinsViewController/*, Controller*/, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var getAmountTextField: UITextField!
  @IBAction func useMaxButtonDidTap(_ sender: Any) {}
  @IBAction func didTapExchangeButton(_ sender: Any) {
//    SoundHelper.playSoundIfAllowed(type: .bip)
//    hardImpactFeedbackGenerator.prepare()
//    hardImpactFeedbackGenerator.impactOccurred()
//    AnalyticsHelper.defaultAnalytics.track(event: .convertGetExchangeButton, params: nil)
//    //TODO: Move to input
//    vm.exchange()
  }
  @IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var getCoinErrorLabel: UILabel!
  @IBOutlet weak var amountErrorLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = GetCoinsViewModel

  func configure(with viewModel: GetCoinsViewModel) {
    //Input
    spendCoinTextField
      .rx
      .text
      .subscribe(viewModel.input.spendCoin)
      .disposed(by: disposeBag)
    
    getAmountTextField
      .rx
      .text
      .subscribe(viewModel.input.getAmount)
      .disposed(by: disposeBag)

    getCoinTextField
      .rx
      .text
      .asDriver()
      .drive(viewModel.input.getCoin)
      .disposed(by: disposeBag)

    exchangeButton
      .rx
      .tap
      .asDriver()
      .drive(viewModel.input.didTapExchangeButton)
      .disposed(by: disposeBag)

    //Output
    viewModel
      .output
      .spendCoin
      .filter({ (val) -> Bool in
        return val != nil && val != ""
      })
      .asDriver(onErrorJustReturn: nil)
      .drive(spendCoinTextField.rx.text)
      .disposed(by: disposeBag)
    
    viewModel
      .output
      .approximately
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: nil)
      .drive(self.approximately.rx.text)
      .disposed(by: disposeBag)
    
    viewModel
      .output
      .isApproximatelyLoading
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (val) in
        if val {
          self?.getActivityIndicator.isHidden = false
          self?.getActivityIndicator.startAnimating()
        } else {
          self?.getActivityIndicator.isHidden = true
          self?.getActivityIndicator.stopAnimating()
        }
      }).disposed(by: disposeBag)

    viewModel
      .output
      .isButtonEnabled
      .asDriver(onErrorJustReturn: false)
      .drive(exchangeButton.rx.isEnabled)
      .disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel as! GetCoinsViewModel)

    let imageView = UIImageView(image: UIImage(named: "textFieldSelectIcon"))
    let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 5.0))
    imageView.frame = CGRect(x: 0.0, y: 22.0, width: 10.0, height: 5.0)
    rightView.isUserInteractionEnabled = false
    rightView.addSubview(imageView)
    spendCoinTextField?.rightView = rightView
    spendCoinTextField?.rightViewMode = .always

    viewModel.isLoading.asObservable().subscribe(onNext: { [weak self] (val) in
      if val {
//        self?.exchangeButton.isEnabled = false
        self?.buttonActivityIndicator.startAnimating()
        self?.buttonActivityIndicator.isHidden = false
      } else {
//        self?.exchangeButton.isEnabled = true
        self?.buttonActivityIndicator.stopAnimating()
        self?.buttonActivityIndicator.isHidden = true
      }
    }).disposed(by: disposeBag)

    viewModel.errorNotification.asObservable().filter({ (notification) -> Bool in
      return nil != notification
    }).subscribe(onNext: { (notification) in
      BannerHelper.performErrorNotification(title: notification!)
    }).disposed(by: disposeBag)

    viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
      return nil != notification
    }).subscribe(onNext: { (notification) in
      BannerHelper.performSuccessNotification(title: notification!)
    }).disposed(by: disposeBag)

    viewModel.shouldClearForm.asObservable().filter({ (val) -> Bool in
      return val
    }).subscribe(onNext: { [weak self] (_) in
      self?.clearForm()
    }).disposed(by: disposeBag)

//    Session.shared.allBalances.asObservable().subscribe(onNext: { [weak self] (_) in
//      self?.spendCoinTextField.text = self?.vm.spendCoinText
//      if self?.vm.hasMultipleCoins ?? false {
//        self?.spendCoinTextField?.rightViewMode = .always
//      } else {
//        self?.spendCoinTextField?.rightViewMode = .never
//      }
//    }).disposed(by: disposeBag)

    viewModel.amountError.asObservable().subscribe(self.amountErrorLabel.rx.text).disposed(by: disposeBag)

    viewModel.getCoinError.asObservable().subscribe(onNext: { [weak self] (val) in
      self?.getCoinErrorLabel.text = val
    }).disposed(by: disposeBag)

    viewModel.coinIsLoading.asObservable().subscribe(onNext: { (val) in
      if val {
        self.getCoinActivityIndicator.isHidden = false
        self.getCoinActivityIndicator.startAnimating()
      } else {
        self.getCoinActivityIndicator.isHidden = true
        self.getCoinActivityIndicator.stopAnimating()
      }
    }).disposed(by: disposeBag)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  // MARK: - UITextFieldDelegate

  override func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if textField == self.spendCoinTextField {
      scrollView.endEditing(true)
      showPicker()
      return false
    } else if textField == self.approximately {
      return false
    }
    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == self.getCoinTextField {
      scrollView.endEditing(true)
    }
    return true
  }

  private func shouldShowPicker() -> Bool {
    return true//viewModel.pickerItems().count > 1
  }

  // MARK: -

  func clearForm() {
    self.getAmountTextField.text = ""
    self.getCoinTextField.text = ""
  }

//  override func showPicker() {
//    let items = viewModel.spendCoinPickerItems
//
//    guard items.count > 0 else {
//      return
//    }
//
//    let data: [[String]] = [items.map({ (item) -> String in
//      let balanceString = CurrencyNumberFormatter
//        .formattedDecimal(with: (item.balance ?? 0),
//                          formatter: coinFormatter)
//      return (item.coin ?? "") + " (" + balanceString + ")"
//    })]
//
//    let picker = McPicker(data: data)
//    picker.toolbarButtonsColor = .white
//    picker.toolbarDoneButtonColor = .white
//    picker.toolbarBarTintColor = UIColor(hex: 0x4225A4)
//    picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
//    picker.show { [weak self] (selected) in
//      guard let coin = selected[0] else {
//        return
//      }
//      if let item = items.filter({ (item) -> Bool in
//        let balanceString = CurrencyNumberFormatter.formattedDecimal(with: (item.balance ?? 0),
//                                                                     formatter: self!.coinFormatter)
//        return (item.coin ?? "") + " (" + balanceString + ")" == coin
//      }).first {
////        self?.viewModel.selectedAddress = item.address
//        self?.viewModel.selectedCoin = item.coin
//      }
////      self?.viewModel.spendCoin.value = coin
//    }
//  }

}

extension GetCoinsViewController: IndicatorInfoProvider {

  func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: "Buy".localized())
  }

}
