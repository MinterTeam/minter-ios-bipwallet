//
//  ShareViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture

class ShareViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var qrCode: UIImageView!
  @IBOutlet weak var address: UILabel!
  @IBOutlet weak var copyButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var copiedView: UIView!
  @IBOutlet weak var addressView: UIView!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ShareViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ShareViewModel) {
    viewModel.output.image.asDriver(onErrorJustReturn: nil).drive(qrCode.rx.image).disposed(by: disposeBag)
    viewModel.output.address.asDriver(onErrorJustReturn: "").drive(address.rx.text).disposed(by: disposeBag)
    viewModel.output.copied.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] (_) in
      UIView.animate(withDuration: 0.25, animations: {
        self?.copiedView.alpha = 1.0
      }) { (suc) in
        UIView.animate(withDuration: 0.25,
                       delay: 3,
                       options: [.curveEaseInOut],
                       animations: {

          self?.copiedView.alpha = 0.0
        })
      }
    }).disposed(by: disposeBag)

    shareButton.rx.tap.asDriver().drive(viewModel.input.didTapShare).disposed(by: disposeBag)
    addressView.rx.tapGesture().when(.ended).map {_ in}.asDriver(onErrorJustReturn: ()).drive(viewModel.input.didTapCopy).disposed(by: disposeBag)

  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    (view as? HandlerView)?.title = "Your Address".localized()

    configure(with: viewModel)
  }

}
