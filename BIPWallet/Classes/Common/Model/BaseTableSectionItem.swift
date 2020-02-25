//
//  BaseTableSectionItem.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxDataSources

struct BaseTableSectionItem: AnimatableSectionModelType, IdentifiableType, Equatable {

	static func == (lhs: BaseTableSectionItem, rhs: BaseTableSectionItem) -> Bool {
		return lhs.identifier == rhs.identifier
	}

  var identifier: String

	var header: String? = ""

	var items: [BaseCellItem]

  init(identifier: String, header: String? = "", items: [BaseCellItem] = []) {
    self.identifier = identifier
		self.header = header
		self.items = items
	}

	// MARK: -

	var identity: String {
		return identifier
	}

	typealias Identity = String

	typealias Item = BaseCellItem

	init(original: BaseTableSectionItem, items: [Item]) {
		self = original
		self.items = items
	}
}
