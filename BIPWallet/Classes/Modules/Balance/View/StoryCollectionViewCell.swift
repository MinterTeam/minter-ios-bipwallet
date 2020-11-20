//
//  StoryCollectionViewCell.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21.10.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import AlamofireImage

class StoryCollectionViewCellItem: BaseCellItem {
  var title: String?
  var isNew: Bool = false
  var backgroundImageURL: String?
}

class StoryCollectionViewCell: UICollectionViewCell, Configurable {

  // MARK: - IBOutlet

  @IBOutlet weak var backgroundImage: UIImageView! {
    didSet {
      backgroundImage.layer.cornerRadius = 8.0
    }
  }
  @IBOutlet weak var storiesBackgroundImage: UIImageView!
  @IBOutlet weak var storyTitle: UILabel!

  // MARK: -

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    let gradient = CAGradientLayer()
    gradient.frame = self.backgroundImage.bounds
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
    gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
    gradient.endPoint = CGPoint(x: 0.5, y: 2.0)
    self.backgroundImage?.layer.addSublayer(gradient)

    layoutIfNeeded()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    self.backgroundImage.image = UIImage(named: "storiesBackground")
  }

  // MARK: -

  func configure(item: BaseCellItem) {
    guard let item = item as? StoryCollectionViewCellItem else { return }

    self.backgroundImage.setImage(urlString: item.backgroundImageURL ?? "",
                                  placeHolderImage: UIImage(named: "storiesBackground")) { (_) in

    }
    self.storyTitle.text = String(htmlString: item.title ?? "")
    self.storiesBackgroundImage.isHidden = !item.isNew
  }

}
