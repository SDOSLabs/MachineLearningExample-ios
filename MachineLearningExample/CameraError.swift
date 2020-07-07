//
//  CameraError.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 06/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import Foundation
import UIKit

enum CameraError: Error {
    case cameraPermissionDenied, videoCaptureNotFound
}
