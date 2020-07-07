//
//  VideoCaptureNotFoundAlertControllerError.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 06/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import Foundation
import UIKit

struct VideoCaptureNotFoundAlertControllerError: AlertControllerError {
    var title: String? {
        return "Error"
    }
    
    var message: String {
        return "No se ha encontrado ninguna cámara en el dispositivo. Utilice un dispositivo con cámara."
    }
    
    var actions: [UIAlertAction] {
        return [
            UIAlertAction(title: "OK", style: .cancel, handler: nil)
        ]
    }
    
    var style: UIAlertController.Style {
        return .alert
    }
}
