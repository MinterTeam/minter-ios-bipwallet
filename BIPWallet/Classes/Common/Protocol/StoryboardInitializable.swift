//
//  StoryboardInitializable.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 14.02.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit

protocol StoryboardInitializable {
  static var storyboardIdentifier: String { get }
}

extension StoryboardInitializable where Self: UIViewController {

  static var storyboardIdentifier: String {
    return String(describing: Self.self)
  }

  static func initFromStoryboard(name: String = "Main") -> Self {
    let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
    return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
  }
}
