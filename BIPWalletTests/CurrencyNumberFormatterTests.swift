import XCTest
@testable import BIPWallet
import secp256k1

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

  func testNumbers6() throws {
    let decimal = Decimal(0.999996)
    let correctValue = "0.99999600"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }

  func testNumbers7() throws {
    let decimal = Decimal(0.999999999999999957)
    let correctValue = "1.0000"
    let formatter = CurrencyNumberFormatter.coinFormatter
    let val = CurrencyNumberFormatter.formattedDecimal(with: decimal, formatter: formatter)
    XCTAssert(val == correctValue)
  }
//    func testSigner() throws {
//        RawTransactionSigner.sign(<#T##Data#>, privateKey: <#T##Data#>)
//        
//        
//        
//    }
    
    func testSecp256k1Signing() {
         // Replace with your private key in hexadecimal format
         let privateKeyHex = "YOUR_PRIVATE_KEY_HEX_STRING"
         
         // Convert the private key from hexadecimal to Data
         let privateKeyData = Data(hex: privateKeyHex)
         
         // Create a secp256k1 key pair using the private key
         let keyPair = ECDSAKey(privateKey: privateKeyData)
         
         // Data to be signed
         let dataToSign = "Hello, World!".data(using: .utf8)!
         
         do {
             // Sign the data using the secp256k1 private key
             let signature = try keyPair.sign(dataToSign)
             
             // Verify that the signature is valid
             let isSignatureValid = try keyPair.verify(signature: signature, message: dataToSign)
             
             XCTAssertTrue(isSignatureValid, "Signature is valid")
         } catch {
             XCTFail("Failed to sign or verify the signature: \(error)")
         }
     }
}
