//
//  DelegatedTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import AlamofireImage

class DelegatedTableViewCellItem: BaseCellItem {
  var title: String?
  var iconURL: URL?
  var iconImage: UIImage?
  var publicKey: String?
  var validatorDesc: String?

  var didTapAdd = PublishSubject<Void>()
  var didTapCopy = PublishSubject<Void>()
}

class DelegatedTableViewCell: BaseCell {

	// MARK: -

  @IBOutlet weak var validatorName: UILabel!
  @IBOutlet weak var validatorIcon: UIImageView! {
    didSet {
      validatorIcon.layer.cornerRadius = 12.0
    }
  }
  @IBOutlet weak var publicKey: UILabel!
  @IBOutlet weak var validatorDesc: UILabel!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var copyButton: UIButton!

	// MARK: -

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  // MARK: -

  override func configure(item: BaseCellItem) {
    guard let item = item as? DelegatedTableViewCellItem else {
      return
    }

    self.validatorName.text = item.title ?? TransactionTitleHelper.title(from: item.publicKey ?? "")

    self.publicKey.text = TransactionTitleHelper.title(from: item.publicKey ?? "")

    self.validatorIcon.image = UIImage(named: "DelegateIcon")
    if let image = item.iconURL {
      self.validatorIcon.af_setImage(withURL: image,
                                     placeholderImage: UIImage(named: "DelegateIcon"),
                                     filter: nil,
                                     progress: { (progress) in },
                                     progressQueue: DispatchQueue.main,
                                     imageTransition: UIImageView.ImageTransition.crossDissolve(0.1),
                                     runImageTransitionIfCached: false) { (image) in }
    }

    if let image = item.iconImage {
      self.validatorIcon.image = image
    }

    validatorDesc.text = item.validatorDesc

    addButton.rx.tap.asDriver().drive(item.didTapAdd).disposed(by: disposeBag)
    copyButton.rx.tap.asDriver().drive(item.didTapCopy).disposed(by: disposeBag)
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    self.validatorIcon?.image = nil
  }
}
