//
//  CurrencyNumberFormatterTests.swift
//  BIPWalletTests
//
//  Created by Alexey Sidorov on 11.05.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import XCTest
@testable import BIPWallet

class CurrencyNumberFormatterTests: XCTestCase {

  override func setUpWithError() throws {
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testNumbers1() throws {
    let decimal = Decimal(0.01)
    let correctValue = "0.0100"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }
  
  func testNumbers2() throws {
    let decimal = Decimal(1.0)
    let correctValue = "1.0000"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }

  func testNumbers3() throws {
    let decimal = Decimal(0.911119999)
    let correctValue = "0.91112000"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }

  func testNumbers4() throws {
    let decimal = Decimal(1234567890.911119999)
    let correctValue = "1 234 567 890.9111"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }

  func testNumbers5() throws {
    let decimal = Decimal(1.2)
    let correctValue = "1.2000"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }

}
