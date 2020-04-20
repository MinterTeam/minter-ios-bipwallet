//
//  ValidatorService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 17.04.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol ValidatorService {
  func validators() -> Observable<[ValidatorItem]>
  func updateValidators()
}
