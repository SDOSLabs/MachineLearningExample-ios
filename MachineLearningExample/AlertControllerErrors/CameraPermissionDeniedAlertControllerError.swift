//
//  CameraPermissionDeniedAlertControllerError.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 06/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import Foundation
import UIKit

struct CameraPermissionDeniedAlertControllerError: AlertControllerError {
    var title: String? {
        return "Error"
    }
    
    var message: String {
        return "Se necesitan permisos de acceso a la cámara para poder hacer uso de Machine Learning. Actívalos desde Ajustes."
    }
    
    var actions: [UIAlertAction] {
        return [
            UIAlertAction(title: "Ir a Ajustes", style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        ]
    }
    
    var style: UIAlertController.Style {
        return .alert
    }
}
