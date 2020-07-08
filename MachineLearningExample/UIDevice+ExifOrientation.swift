//
//  UIDevice+ExifOrientation.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 07/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    
    func exifOrientation() -> CGImagePropertyOrientation {
        let exifOrientation: CGImagePropertyOrientation
        
        switch orientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
