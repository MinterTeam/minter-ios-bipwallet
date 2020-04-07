//
//  Notifiable.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

protocol Notifiable {
	var title: String? { get set }
	var text: String? { get set }
	init(title: String?, text: String?)
}

struct NotifiableError: Notifiable {
	var title: String?
	var text: String?

	init(title: String? = nil, text: String? = nil) {
		self.title = title
		self.text = text
	}
}

struct NotifiableSuccess: Notifiable {
	var title: String?
	var text: String?

	init(title: String? = nil, text: String? = nil) {
		self.title = title
		self.text = text
	}
}
