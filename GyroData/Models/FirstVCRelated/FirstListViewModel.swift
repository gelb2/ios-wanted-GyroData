//
//  FirstListViewModel.swift
//  GyroData
//
//  Created by pablo.jee on 2022/09/20.
//

import Foundation

class FirstListViewModel {
    // MARK: Input
    var didSelectRow: (Int) -> () = { indexPathRow in }
    var didSelectPlayAction: (Int) -> () = { indexPathRow in }
    var didReceiveMotionTasks: ([MotionTask]) -> () = { motionTasks in }
    
    // MARK: Output
    var propagateDidSelectRowEvent: (MotionTask) -> () = { motion in }
    var propagateDidSelectPlayActionEvent: (MotionTask) -> () = { motion in }
    var motionDatas: [MotionTask] {
        return _motionDatas
    }
    var didReceiveViewModel: ( ((Void)) -> () )?
    
    // MARK: Properties
    private var _motionDatas: [MotionTask]
    
    // MARK: Init
    init(_ motionDatas: [MotionTask]) {
        self._motionDatas = motionDatas
        bind()
    }
    
    // MARK: Bind
    private func bind() {
        didSelectRow = { [weak self] indexPathRow in
            guard let self = self else { return }
            let motion = self._motionDatas[indexPathRow]
            self.propagateDidSelectRowEvent(motion)
        }
        didSelectPlayAction = { [weak self] indexPathRow in
            guard let self = self else { return }
            let motion = self._motionDatas[indexPathRow]
            self.propagateDidSelectPlayActionEvent(motion)
        }
        didReceiveMotionTasks = { [weak self] motionTasks in
            self?.populateData(result: motionTasks)
            self?.didReceiveViewModel?(())
        }
    }
    
    private func populateData(result: [MotionTask]) {
        self._motionDatas = result
    }
}
