//
//  SentViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SentPopupViewModel: PopupViewModel, ViewModel {

	// MARK: - ViewModelProtocol

	struct Input {}

	struct Output {}

	struct Dependency {
    var recipientInfoService: RecipientInfoService
  }

	var input: SentPopupViewModel.Input!
	var output: SentPopupViewModel.Output!
  var dependency: SentPopupViewModel.Dependency!

	// MARK: -

	var desc: String?
	var coin: String?
	var avatarImage: UIImage?
	var avatarImageURL: URL?
	var noAvatar: Bool = false
	var username: String?
	var actionButtonTitle: String?
	var secondButtonTitle: String?

  init(dependency: Dependency) {
    super.init()

    self.dependency = dependency
    self.input = Input()
    self.output = Output()
  }

}
