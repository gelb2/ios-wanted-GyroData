//
//  SceneAction.swift
//  GyroData
//
//  Created by 한경수 on 2022/09/27.
//

import Foundation

// SceneAction을 보낼 수 있는 ViewController가 준수하는 프로토콜
protocol SceneActionSendable {
    func sendAction(scene: SceneCategory)
}

// SceneAction을 받을 수 있는 Model이 준수하는 프로토콜
protocol SceneActionReceiver {
    var didReceiveSceneAction: (SceneAction) -> () { get set }
}

// 모든 SceneAction이 준수하는 프로토콜
protocol SceneAction {
    
}