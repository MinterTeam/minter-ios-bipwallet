//
//  SpendCoinsViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 19/03/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip
import RxBiBinding

class SpendCoinsViewController: ConvertCoinsViewController, StoryboardInitializable {

  // MARK: - IBOutlet

  @IBOutlet weak var useMaxButton: UIButton!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var spendAmountTextField: UITextField!
  @IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
  @IBAction func didTapExchange(_ sender: Any) {
    
  }
  @IBOutlet weak var amountErrorLabel: UILabel!
  @IBOutlet weak var getCoinErrorLabel: UILabel!
  @IBAction func didTapUseMax(_ sender: Any) {
    
  }

  // MARK: - ControllerProtocol

  typealias ViewModelType = SpendCoinsViewModel

  func configure(with viewModel: SpendCoinsViewModel) {
    //Input
//    spendAmountTextField.rx.text.asObservable()
//      .subscribe(viewModel.input.spendAmount)
//      .disposed(by: disposeBag)

    (spendAmountTextField.rx.text <-> viewModel.input.spendAmount).disposed(by: disposeBag)

    getCoinTextField.rx.text.asObservable()
      .subscribe(viewModel.input.getCoin)
      .disposed(by: disposeBag)

    spendCoinTextField.rx.text.asObservable()
      .subscribe(viewModel.input.spendCoin)
      .disposed(by: disposeBag)

    useMaxButton.rx.tap.asObservable()
      .subscribe(viewModel.input.useMaxDidTap)
      .disposed(by: disposeBag)

    exchangeButton.rx.tap.asObservable()
      .subscribe(viewModel.input.didTapExchangeButton)
      .disposed(by: disposeBag)

    //Output
    viewModel
      .output
      .approximately
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: nil)
      .drive(approximately.rx.text)
      .disposed(by: disposeBag)

    viewModel
      .output
      .spendCoin
      .filter({ (val) -> Bool in
        return val != nil && val != ""
      })
      .asDriver(onErrorJustReturn: nil)
      .drive(self.spendCoinTextField.rx.text)
      .disposed(by: self.disposeBag)

    viewModel
      .output
      .hasMultipleCoinsObserver
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (has) in
        self?.spendCoinTextField?.rightViewMode = has ? .always : .never
      }).disposed(by: self.disposeBag)

    viewModel
      .output
      .isButtonEnabled
      .asDriver(onErrorJustReturn: true)
      .drive(self.exchangeButton.rx.isEnabled).disposed(by: self.disposeBag)

    viewModel.output.isLoading.asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (val) in
        if val {
          self?.buttonActivityIndicator.startAnimating()
          self?.buttonActivityIndicator.isHidden = false
        } else {
          self?.buttonActivityIndicator.stopAnimating()
          self?.buttonActivityIndicator.isHidden = true
        }
      }).disposed(by: disposeBag)

    viewModel.output.errorNotification.asDriver(onErrorJustReturn: nil)
      .filter({ (notification) -> Bool in
        return notification != nil
      }).drive(onNext: { (notification) in
        BannerHelper.performErrorNotification(title: notification ?? "",
                                              subtitle: nil)
      }).disposed(by: self.disposeBag)

    viewModel
      .output
      .shouldClearForm
      .filter({ (val) -> Bool in
        return val
      }).subscribe(onNext: { [weak self] (val) in
        self?.clearForm()
      }).disposed(by: disposeBag)

    viewModel
      .output
      .isCoinLoading
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] (val) in
        self?.getCoinActivityIndicator.isHidden = !val
        if val {
          self?.getCoinActivityIndicator.startAnimating()
        } else {
          self?.getCoinActivityIndicator.stopAnimating()
        }
      }).disposed(by: disposeBag)

    viewModel
      .output
      .amountError
      .asDriver(onErrorJustReturn: nil)
      .drive(amountErrorLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel
      .output
      .getCoinError
      .asDriver(onErrorJustReturn: nil)
      .drive(getCoinErrorLabel.rx.text)
      .disposed(by: disposeBag)

    viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
      return nil != notification
    }).subscribe(onNext: { (notification) in
      BannerHelper.performSuccessNotification(title: notification ?? "",
                                              subtitle: nil)
    }).disposed(by: disposeBag)

    viewModel
      .output
      .spendAmount
      .asDriver(onErrorJustReturn: nil)
      .map({ (str) -> String? in
        str?.replacingOccurrences(of: ",", with: ".")
      })
      .drive(spendAmountTextField.rx.text)
      .disposed(by: disposeBag)

    self.viewModel = viewModel
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    configure(with: viewModel as! SpendCoinsViewModel)
  }

  private func shouldShowPicker() -> Bool {
    return true//(viewModel.pickerItems().count) > 1
  }

  // MARK: -

  func clearForm() {
    self.spendAmountTextField.text = ""
    self.getCoinTextField.text = ""
  }

}

extension SpendCoinsViewController: IndicatorInfoProvider {

  func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: "Sell".localized())
  }

}
