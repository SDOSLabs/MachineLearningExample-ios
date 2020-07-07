//
//  AlertControllerError.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 06/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import Foundation
import UIKit

protocol AlertControllerError {
    var title: String? { get }
    var message: String { get }
    var actions: [UIAlertAction] { get }
    var style: UIAlertController.Style { get }
}

extension CameraError {
    func toAlertControllerError() -> AlertControllerError {
        switch self {
        case .cameraPermissionDenied:
            return CameraPermissionDeniedAlertControllerError()
        case .videoCaptureNotFound:
            return VideoCaptureNotFoundAlertControllerError()
        }
    }
}
