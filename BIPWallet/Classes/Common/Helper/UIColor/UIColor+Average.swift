//
//  UIColor+Average.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 09.11.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import UIKit
import CoreGraphics

extension UIImage {

  var averageColor: UIColor? {
    guard let inputImage = CIImage(image: self) else { return nil }

    let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

    guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
    guard let outputImage = filter.outputImage else { return nil }

    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: [.workingColorSpace: kCFNull])
    context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

    return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
  }
}

extension UIColor {
  var inverted: UIColor {
    var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
    return getRed(&r, green: &g, blue: &b, alpha: &a) ? UIColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: a) : .black
  }
}

extension CGImage {

  var isDark: Bool {
    get {
      guard let imageData = self.dataProvider?.data else { return false }
      guard let ptr = CFDataGetBytePtr(imageData) else { return false }
      let length = CFDataGetLength(imageData)
      let threshold = Int(Double(self.width * self.height) * 0.45)
      var darkPixels = 0
      for i in stride(from: 0, to: length, by: 4) {
        let r = ptr[i]
        let g = ptr[i + 1]
        let b = ptr[i + 2]
        let luminance = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
        if luminance < 150 {
          darkPixels += 1
          if darkPixels > threshold {
            return true
          }
        }
      }
      return false
    }
  }
}

extension UIImage {

  var isDark: Bool {
    get {
      return self.cgImage?.isDark ?? false
    }
  }
}
