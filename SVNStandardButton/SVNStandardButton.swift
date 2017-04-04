//
//  SVNStandardButton.swift
//  SVNStandardButton
//
//  Created by Aaron Dean Bikis on 4/3/17.
//  Copyright © 2017 7apps. All rights reserved.
//

import UIKit

public enum SVNStandardButtonType {
    case circle, exit, checkMark, plus
}


public class SVNStandardButton: UIButton {
    
    public enum LayerType {
        case circle, firstLine, secondLine, checkMark
    }
    
    private enum ErrorType {
        case nonInstanciatedLayer
        case notSupportedAnimation
        case unSupportedLayer
        
        var description: String {
            switch self {
            case .nonInstanciatedLayer:
                return "a layer was not instaciated prior to trying to animate it"
            case .notSupportedAnimation:
                return "This animation is not yet supported"
            case .unSupportedLayer:
                return "This layer is currently unspported"
                
            }
        }
    }
    
    public var currentType: SVNStandardButtonType?
    
    public var customLayers: [LayerType: CALayer]?
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.customLayers?.forEach({
            $0.value.frame = self.bounds
        })
    }
    
    /**
     Creates and add a layer or layers of the type to the button's subview
     - parameters: 
        - state: SVNStandardButtonType the button type to create
        - fillColor: UIColor the color to fill the layers
        - strokeColor: UIColor the color to stroke the layers with
     - important: will remove all previously added SVNStandardButtonType layers
    */
    public func configure(for state: SVNStandardButtonType, fillColor: UIColor, strokeColor: UIColor) {
        if customLayers != nil {
            customLayers?.forEach({ $0.value.removeFromSuperlayer() })
            customLayers = nil
        }
        self.currentType = state
        switch state {
        case .checkMark:
            self.createCheckMark(withFillColor: fillColor, strokeColor: strokeColor)
        case .circle:
            self.createCircleLayer(with: fillColor, strokeColor: strokeColor)
        case .exit:
            self.createTwoLineShape(shapeType: .exit, strokeColor: strokeColor, fillColor: fillColor)
        case .plus:
            self.createTwoLineShape(shapeType: .plus, strokeColor: strokeColor, fillColor: fillColor)
        }
    }
    
    /**
     Will animate using defaults 
     - parameters:
        - startState: *SVNStandardButtonType* the state that the current layer is in
        - endState: *SVNStandardButtonType* the state the the layer will animate to
        - startDuration: Double the duration for the first half of the animation. default is 0.5
        - endDuration: Double the duration for the second half of the animation. default is 0.5
     currently supported Animations : 
     1.(requires a previously created circle layer)
     start .circle
     end: .exit
     2.(requires a circle layer and a twoLine shape)
     start: .exit || .plus
     end: .circle
    */
    public func animate(from startState: SVNStandardButtonType, to endState: SVNStandardButtonType, startDuration: Double = 0.5, endDuration: Double = 0.5){
        switch (startState, endState) {
            //Animate to exit
        case (SVNStandardButtonType.circle, SVNStandardButtonType.exit):
            self.animateCircleFill(withColor: .white, duration: startDuration, withBlock: {
                self.createTwoLineShape(shapeType: .exit, strokeColor: .white, fillColor: .clear)
                self.animateCircleFill(withColor: .red, duration: endDuration, withBlock: nil)
            })
            //Animate to circle
        case (SVNStandardButtonType.exit, SVNStandardButtonType.circle):
            self.animateExit(withColor: .white, duration: startDuration, withBlock: {
                guard let firstLineLayer = self.customLayers?[LayerType.firstLine],
                    let secondLineLayer = self.customLayers?[LayerType.secondLine] else { fatalError(ErrorType.nonInstanciatedLayer.description) }
                firstLineLayer.removeFromSuperlayer()
                secondLineLayer.removeFromSuperlayer()
                self.animateCircleFill(withColor: .clear, duration: endDuration, withBlock: nil)
            })
            
        default:
            fatalError(ErrorType.notSupportedAnimation.description)
        }
    }
    
    /**
     Instaciates a two line shape 
     - important: Currently only supports types .exit and .plus
     - parameters:
        - type: SVNStandardButtonType
        - strokeColor: UIColor
        - fillColor: UIColor
    */
    public func createTwoLineShape(shapeType type: SVNStandardButtonType, strokeColor: UIColor, fillColor: UIColor) {
        let middle = min(bounds.width, bounds.height) * 0.5
        let plus = [CGPoint(x: middle, y: middle/2),
                    CGPoint(x:middle, y:bounds.height - middle/2),
                    CGPoint(x: middle/2, y: middle),
                    CGPoint(x: bounds.width - middle/2, y: middle)]
        
        let exit = [CGPoint(x: middle - middle/2, y: middle - middle/2),
                    CGPoint(x: middle + middle/2, y: bounds.height - (middle  - middle/2)),
                    CGPoint(x: middle + middle/2, y: middle - middle/2),
                    CGPoint(x: middle - middle/2, y: bounds.height - (middle - middle/2))]
        var points :[CGPoint]!
        
        switch type {
        case .exit:
            points = exit
        case .plus:
            points = plus
        default:
            fatalError()
        }
        
        let firstLineLayer = CAShapeLayer()
        firstLineLayer.strokeColor = strokeColor.cgColor
        firstLineLayer.fillColor = fillColor.cgColor
        firstLineLayer.lineWidth = 2.5
        
        let secondLineLayer = CAShapeLayer()
        secondLineLayer.strokeColor = firstLineLayer.strokeColor
        secondLineLayer.fillColor = firstLineLayer.fillColor
        secondLineLayer.lineWidth = firstLineLayer.lineWidth
        
        let lineWidth: CGFloat = 2.5
        
        let firstLine = UIBezierPath()
        
        firstLine.lineWidth = lineWidth
        firstLine.move(to: points[0])
        firstLine.addLine(to: points[1])
        
        let secondLine = UIBezierPath()
        
        secondLine.lineWidth = lineWidth
        secondLine.move(to: points[2])
        secondLine.addLine(to: points[3])
        
        firstLineLayer.path = firstLine.cgPath
        secondLineLayer.path = secondLine.cgPath
        
        layer.addSublayer(firstLineLayer)
        layer.addSublayer(secondLineLayer)
        customLayers = [LayerType.firstLine: firstLineLayer,
                        LayerType.secondLine: secondLineLayer]
    }
    
    /**
     Creates a Circle Layer and adds it to the button's sublayer
     - parameters :
        - fillColor: UIColor
        - strokeColor: UIColor
    */
    public func createCircleLayer(with fillColor: UIColor, strokeColor: UIColor){
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = fillColor.cgColor
        circleLayer.strokeColor = strokeColor.cgColor
        circleLayer.lineWidth = 2.5
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
        self.customLayers = [LayerType.circle: circleLayer]
    }
    
    
    public func createCheckMark(withFillColor fillColor: UIColor, strokeColor: UIColor){
        //Points are plotted clockwise
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = fillColor.cgColor
        circleLayer.strokeColor = strokeColor.cgColor
        circleLayer.lineWidth = 1.0
        layer.addSublayer(circleLayer)
        
        let checkMarkLayer = CAShapeLayer()
        let checkMarkPath = UIBezierPath()
        
        checkMarkLayer.strokeColor = UIColor.white.cgColor
        checkMarkLayer.fillColor = UIColor.clear.cgColor
        checkMarkLayer.lineWidth = 2.5
        
        let middle = max(bounds.width, bounds.height) * 0.5
        
        checkMarkPath.move(to: CGPoint(x: middle / 2,
                                       y: middle))
        
        checkMarkPath.addLine(to: CGPoint(x: middle,
                                          y: bounds.height - middle/2))
        
        checkMarkPath.addLine(to: CGPoint(x: bounds.width - middle/2,
                                          y: middle / 1.5))
        
        checkMarkLayer.path = checkMarkPath.cgPath
        self.layer.addSublayer(checkMarkLayer)
        self.customLayers = [LayerType.circle: circleLayer,
                             LayerType.checkMark: checkMarkLayer]
    }
    
    private func animateCircleFill(withColor color: UIColor, duration: Double, withBlock block: (() -> Void)?) {
        guard let circleLayer = customLayers?[LayerType.circle] else { fatalError(ErrorType.nonInstanciatedLayer.description) }
        CATransaction.begin()
        let fillAnimation = CABasicAnimation(keyPath: "fillColor")
        fillAnimation.duration = duration
        fillAnimation.toValue = color.cgColor
        fillAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        fillAnimation.fillMode = kCAFillModeBoth
        fillAnimation.isRemovedOnCompletion = false
        circleLayer.add(fillAnimation, forKey: fillAnimation.keyPath!)
        CATransaction.setCompletionBlock(block)
        CATransaction.commit()
    }
    
    
    private func animateExit(withColor color: UIColor, duration: Double, withBlock block: (() -> Void)?) {
        guard let firstLineLayer = self.customLayers?[LayerType.firstLine],
            let secondLineLayer = self.customLayers?[LayerType.secondLine] else { fatalError(ErrorType.nonInstanciatedLayer.description) }
        CATransaction.begin()
        let strokeAnimation = CABasicAnimation(keyPath: "strokeColor")
        strokeAnimation.toValue = color.cgColor
        strokeAnimation.duration = duration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        strokeAnimation.fillMode = kCAFillModeBoth
        strokeAnimation.isRemovedOnCompletion = false
        firstLineLayer.add(strokeAnimation, forKey: strokeAnimation.keyPath!)
        secondLineLayer.add(strokeAnimation, forKey: strokeAnimation.keyPath!)
        CATransaction.setCompletionBlock(block)
        CATransaction.commit()
    }
    
}
