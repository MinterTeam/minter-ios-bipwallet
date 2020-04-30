//
//  ShareViewController.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 29/04/2020.
//  Copyright 2020 Minter. All rights reserved.
//

import UIKit
import RxSwift

class ShareViewController: BaseViewController, Controller, StoryboardInitializable {

  // MARK: -

  @IBOutlet weak var qrCode: UIImageView!
  @IBOutlet weak var address: UILabel!
  @IBOutlet weak var copyButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!

  // MARK: - ControllerProtocol

  typealias ViewModelType = ShareViewModel

  var viewModel: ViewModelType!

  func configure(with viewModel: ShareViewModel) {
    viewModel.output.image.asDriver(onErrorJustReturn: nil).drive(qrCode.rx.image).disposed(by: disposeBag)
    viewModel.output.address.asDriver(onErrorJustReturn: "").drive(address.rx.text).disposed(by: disposeBag)
    viewModel.output.copied.asDriver(onErrorJustReturn: ()).drive(onNext: { (_) in
      BannerHelper.performCopiedNotification()
    }).disposed(by: disposeBag)

    copyButton.rx.tap.asDriver().drive(viewModel.input.didTapCopy).disposed(by: disposeBag)
    shareButton.rx.tap.asDriver().drive(viewModel.input.didTapShare).disposed(by: disposeBag)
  }

  // MARK: - ViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    (view as? HandlerView)?.title = "Your Address"

    configure(with: viewModel)
  }

}
