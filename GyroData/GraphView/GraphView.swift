//
//  GraphView.swift
//  GyroData
//
//  Created by pablo.jee on 2022/09/21.
//

import UIKit
import SwiftUI
import CoreGraphics

// TODO: 격자 그리드 뷰/효과 추가...여러 그래프에 나오는 격자효과 그거
// TODO: data 배열+path그래프가 화면의 가로 사이즈보다 커질 경우를 대비한 ScrollView 추가?

/*******. 두번째 페이지 *******/
/* graphView
 - acc 혹은 gyro 값들을 화면에 표시한다. acc, gyro 각 x: Red, y: Green, z: Blue의 선으로 표기
 - CAShapeLayer, UIBezierPath, CGMultiplePath 등을 이용해서 값들을 선으로 표시합니다.
 - y축은 초기 범위를 설정하고, 측정된 값이 범위의 최대값보다 클 경우 측정된 값 + (측정된 값 * 0.2) 로 하여 스케일을 다시 설정
 - y축 초기범위는 다시 측정할 경우 초기화
 - x축은 10hz로 60초동안 측정하므로 최대 총 600개의 데이터를 가짐
 */

/* 측정 버튼
 - 측정 버튼을 누르면 타이머가 동작하고, 10hz로 SegmentControl에 설정된 값에 따라서 acc 혹은 gyro의 x, y, z값을 가져옴
 - 타이머는 1초에 10개의 데이터를 가져올 수 있도록 0.1초로 설정하고, timeout 시간은 600.
 - 각 틱마다 x, y, z 값을 모두 저장.
 - 다시 측정하는 경우 기존의 값들을 초기화.
 */

/* 정지 버튼
 - 타이머가 동작할 때만 활성화.
 - 버튼을 누르면 타이머를 멈춤.
 */

/*
 - 측정된 값이 있을 경우 데이터를 CoreData와 FileManager를 이용해서 json으로 저장.
 - 값이 없을 경우 데이터가 없다는 알림을 표시.
 - 저장하는 json의 포맷은 자유롭게 설정.
 - 측정 중 저장버튼을 누를 수 없음.
 - 데이터 저장은 비동기로 처리, Activity Indicator를 표시.
 - 저장이 성공하면 Indicator를 닫고, 첫 번째 페이지로 이동.
 - 저장이 실패하면 Indicator를 닫고, 페이지를 이동하지않고 실패이유 적은 Alert을 띄움.
 */

/*******. 세번째 페이지 *******/
/*
 - 페이지타입은 play 타입과 view 타입...아무래도 첫번째 화면에서 didSelectRow를 누르면 view타입, 스와이프+play 버튼 누르면 play타입 을 띄우길 원하는듯
 - 네비바를 이용해 뒤로가기 지원필요
 - 측정시간을 타이틀로 표시
 - view타입은 GraphView 이용해서 FileManager로 불러온 모든 데이터를 선으로 표시 + 데이터를 한 번에 그래프로 표시해야 함
 - play타입은 타이머를 이용하여 데이터를 재생하는 화면. GraphView 이용하여 모든 데이터를 선으로 표시
   재생버튼, 정지버튼 포함
   재생버튼을 누르면 타이머가 동작. 인터벌은 0.1초. 총 600인터벌, 60초 동안 재생
   재생 시작시 재생버튼은 정지버튼으로 바뀜
   재생버튼 옆에는 재생시간을 표시. 0.1초 단위로 표시
   정지버튼을 누르고 다시 재생할 경우 처음부터 재생
   재생하면서 x y z 의 값에 기반해 GraphView의 선을 갱신.
   x y z 중 하나의 값이라도 없다면 재생을 멈춤
 */

class GraphView: UIView {
    
    //input

    //output
    
    
    //properties
    var viewModel: GraphViewModel = GraphViewModel()
    
    //Point Properties for calculating Path's Position
    
    //path의 y좌표가 이 값의 최대값보다 크거나 작으면 CGAffineTransform을 이용해 뷰의 스케일을 축소한다? path가 잘려서 안 보이면 안되니까?
    lazy var yAxisMiddleRange: ClosedRange<CGFloat> = yAxisMiddleRangeMin...yAxisMiddleRangeMax
    lazy var yAxisMiddleRangeMin: CGFloat = middlePoint.y * 0.2
    lazy var yAxisMiddleRangeMax: CGFloat = middlePoint.y * 1.8
    lazy var yAxisMultiplier: CGFloat = 1.0
    
    lazy var middlePoint: CGPoint = CGPoint(x: 0.0, y: self.frame.height / 2)
    
    lazy var xPreviousPoint: CGPoint = CGPoint(x: 0, y: self.middlePoint.y)
    lazy var xNewPoint: CGPoint = CGPoint(x: 0, y: 0)
    var xPathData: [CGPoint] = []
    
    lazy var yPreviousPoint: CGPoint = CGPoint(x: 0, y: self.middlePoint.y)
    lazy var yNewPoint: CGPoint = CGPoint(x: 0, y: 0)
    var yPathData: [CGPoint] = []
    
    lazy var zPreviousPoint: CGPoint = CGPoint(x: 0, y: self.middlePoint.y)
    lazy var zNewPoint: CGPoint = CGPoint(x: 0, y: 0)
    var zPathData: [CGPoint] = []
    
    let xPath = UIBezierPath()
    let yPath = UIBezierPath()
    let zPath = UIBezierPath()
    
    var lastAppliedTransform: CGAffineTransform?
    
    init(viewModel: GraphViewModel) {
        super.init(frame: .zero)
        
        self.viewModel = viewModel
        initViewHierarchy()
        configureView()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        drawXpath()
        drawYpath()
        drawZpath()
    }
    
    // TODO: 일단 path.close는 "path"를 완전히 다 그렸을 시 close 해줘야 하는 듯 하다. UIGraphicCurrentContext가 close해줘야 하는 것처럼
    //그런데 현 시점 기준으로는 close를 부르나 부르지 않으나 효과가 똑같다.
    //언제 path.close를 확실히 불러줘야 하는지에 대한 검증이 필요해 보인다.
    func drawXpath() {
        guard let receivedData = viewModel.dataSource.last?.xValue else { return }
        
        xPath.move(to: xPreviousPoint)
        
        xNewPoint = CGPoint(x: xPreviousPoint.x + 0.5, y: xPreviousPoint.y + receivedData)
        // 이전 Path들에게 이미 적용된 Transform이 있다면 newPoint에도 해당 Transform을 적용시킨 뒤 선을 그려줘야 합니다. - Eric
        if let lastAppliedTransform {
            xNewPoint = xNewPoint.applying(lastAppliedTransform)
        }
        xPath.addLine(to: xNewPoint)
        
        xPreviousPoint = xNewPoint
        
        reCalculateScale(point: xPreviousPoint)
        
        UIColor.red.setStroke()
        xPath.stroke()
        xPathData.append(xPreviousPoint)
    }
    
    func drawYpath() {
        guard let receivedData = viewModel.dataSource.last?.yValue else { return }
        
        yPath.move(to: yPreviousPoint)
        
        yNewPoint = CGPoint(x: yPreviousPoint.x + 0.5, y: yPreviousPoint.y + receivedData)
        if let lastAppliedTransform {
            yNewPoint = yNewPoint.applying(lastAppliedTransform)
        }
        yPath.addLine(to: yNewPoint)
        
        yPreviousPoint = yNewPoint
        
        reCalculateScale(point: yPreviousPoint)
        
        UIColor.green.setStroke()
        yPath.stroke()
        yPathData.append(yPreviousPoint)
    }
    
    func drawZpath() {
        guard let receivedData = viewModel.dataSource.last?.zValue else { return }
        
        zPath.move(to: zPreviousPoint)
        
        zNewPoint = CGPoint(x: zPreviousPoint.x + 0.5, y: zPreviousPoint.y + receivedData)
        if let lastAppliedTransform {
            zNewPoint = zNewPoint.applying(lastAppliedTransform)
        }
        zPath.addLine(to: zNewPoint)
        
        zPreviousPoint = zNewPoint
        
        reCalculateScale(point: zPreviousPoint)
        
        UIColor.blue.setStroke()
        zPath.stroke()
        zPathData.append(zPreviousPoint)
    }
    
    func reCalculateScale(point: CGPoint) {
        if yAxisMiddleRange ~= point.y {
            yAxisMiddleRangeMin = middlePoint.y * 0.2
            yAxisMiddleRangeMax = middlePoint.y * 1.8
            yAxisMultiplier = 1.0
        } else {
            if point.y > yAxisMiddleRangeMax {
                //middlePoint.y * 1.8
                let calculation = point.y - yAxisMiddleRangeMax
                // 0.95 하드 코딩 대신 늘어난 길이를 계산하여 yAxisMutliper를 결정합니다. - Eric
                yAxisMultiplier = yAxisMultiplier * (yAxisMiddleRangeMax / (yAxisMiddleRangeMax + calculation))
                yAxisMiddleRangeMax = yAxisMiddleRangeMax + calculation
            } else if point.y < yAxisMiddleRangeMin {
                //middlePoint.y * 0.2
                let calculation = yAxisMiddleRangeMin - point.y
                yAxisMultiplier = yAxisMultiplier * ((middlePoint.y - yAxisMiddleRangeMin) / (middlePoint.y - yAxisMiddleRangeMin + calculation))
                yAxisMiddleRangeMin = yAxisMiddleRangeMin - calculation
            }

            let width = UIScreen.main.bounds.width - 32
            let height = width
            
            let transform = CGAffineTransform(1, 0, 0, yAxisMultiplier, 0, height * ((1-yAxisMultiplier)/2))
            xPath.apply(transform)
            yPath.apply(transform)
            zPath.apply(transform)
            
            lastAppliedTransform = transform
            
            // Scaling뿐만 아니라 Transition까지 이전 Path와 previousPoint에 적용하기 위해, yAxisMutliplier를 곱하는 대신,
            // applying 메소드를 통해 transform을 직접 적용하는 형태로 변경했습니다. - Eric
            let newXpathData = xPathData.map { $0.applying(transform) }
            xPathData = newXpathData
            xPreviousPoint = xPreviousPoint.applying(transform)
            
            let newYpathData = yPathData.map { $0.applying(transform) }
            yPathData = newYpathData
            yPreviousPoint = yPreviousPoint.applying(transform)

            let newZpathData = zPathData.map { $0.applying(transform) }
            zPathData = newZpathData
            zPreviousPoint = zPreviousPoint.applying(transform)
        }
    }
    
}

extension GraphView: Presentable {
    func initViewHierarchy() {

    }
    
    func configureView() {
        self.backgroundColor = .black
        xPath.lineWidth = 1 //default
        yPath.lineWidth = 1 //default
        zPath.lineWidth = 1 //default
    }
    
    func bind() {
        
        //드로잉을 위한 데이터소스 변경, 붙이기, 삭제 등 비즈니스 로직
        viewModel.populateData = { [weak self] in
            self?.setNeedsDisplay() //그 다음에 얘를 호출 호출하면
            //다음 드로잉 사이클에 오버라이드한 draw가 불리게 될 것임
        }

        viewModel.populateRemoveAll = { [weak self] in
            guard let self = self else { return }

            self.xPreviousPoint = CGPoint(x: 0, y: self.middlePoint.y)
            self.xNewPoint = CGPoint(x: 0, y: 0)
            
            self.yPreviousPoint = CGPoint(x: 0, y: self.middlePoint.y)
            self.yNewPoint = CGPoint(x: 0, y: 0)
            
            self.zPreviousPoint = CGPoint(x: 0, y: self.middlePoint.y)
            self.zNewPoint = CGPoint(x: 0, y: 0)
            
            self.xPath.removeAllPoints()
            self.yPath.removeAllPoints()
            self.zPath.removeAllPoints()
            self.yAxisMultiplier = 1.0
            
            self.xPathData.removeAll()
            self.yPathData.removeAll()
            self.zPathData.removeAll()
            
            //Path 전부 지우는 경우 Path그릴시 사용했던 트랜스폼도 초기화
            self.lastAppliedTransform = nil
            
            self.setNeedsDisplay()
        }
    }
}
