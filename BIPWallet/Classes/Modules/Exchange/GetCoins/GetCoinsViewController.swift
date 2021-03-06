//
//  GetCoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxBiBinding
import XLPagerTabStrip

class GetCoinsViewController: ConvertCoinsViewController/*, Controller*/, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var getAmountTextField: UITextField!
  @IBAction func useMaxButtonDidTap(_ sender: Any) {}
  @IBAction func didTapExchangeButton(_ sender: Any) {}
  @IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var getCoinErrorLabel: UILabel!
  @IBOutlet weak var amountErrorLabel: UILabel!

  // MARK: - ControllerProtocol

  typealias ViewModelType = GetCoinsViewModel

  func configure(with viewModel: GetCoinsViewModel) {
    //Input
    (spendCoinTextField.rx.text <-> viewModel.input.spendCoin).disposed(by: disposeBag)
    (getAmountTextField.rx.text <-> viewModel.input.getAmount).disposed(by: disposeBag)

    getCoinTextField.rx.text.asDriver()
      .drive(viewModel.input.getCoin)
      .disposed(by: disposeBag)

    exchangeButton.rx.tap.asDriver()
      .drive(viewModel.input.didTapExchangeButton)
      .disposed(by: disposeBag)

    //Output
    viewModel.output.spendCoin
      .filter({ (val) -> Bool in
        return val != nil && val != ""
      })
      .asDriver(onErrorJustReturn: nil)
      .drive(spendCoinTextField.rx.text)
      .disposed(by: disposeBag)
    
    viewModel.output.approximately
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: nil)
      .drive(self.approximately.rx.text)
      .disposed(by: disposeBag)
    
    viewModel.output.isApproximatelyLoading
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

    viewModel.output.isButtonEnabled
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
}

extension GetCoinsViewController: IndicatorInfoProvider {

  func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: "Buy".localized())
  }

}
