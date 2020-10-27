//
//  BaseCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

protocol Configurable {
	func configure(item: BaseCellItem)
}

typealias ConfigurableCell = UITableViewCell & Configurable

class BaseCell: ConfigurableCell {

	var disposeBag = DisposeBag()

	func configure(item: BaseCellItem) {}

	override func prepareForReuse() {
		super.prepareForReuse()
		disposeBag = DisposeBag()
	}
}
