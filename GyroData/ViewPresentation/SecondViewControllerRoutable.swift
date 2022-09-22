//
//  SecondViewControllerRoutable.swift
//  GyroData
//
//  Created by pablo.jee on 2022/09/20.
//

import Foundation
import UIKit

protocol SecondViewControllerRoutable: Routable {
    
}

extension SecondViewControllerRoutable where Self: SecondViewController {
    func route(to Scene: SceneCategory) {
        switch Scene {
        case .close:
            self.navigationController?.popViewController(animated: true)
        default: break
        }
    }
}
