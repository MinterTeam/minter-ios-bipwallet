//
//  String+Localized.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension String {
	func localized(_ comment: String = "") -> String {
		return NSLocalizedString(self, comment: comment)
	}
}

extension String {

    init(htmlString: String) {
        self.init()
        guard let encodedData = htmlString.data(using: .utf8) else {
            self = htmlString
            return
        }

        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
           .documentType: NSAttributedString.DocumentType.html,
           .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let attributedString = try NSAttributedString(data: encodedData,
                                                          options: attributedOptions,
                                                          documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error.localizedDescription)")
            self = htmlString
        }
    }
}
