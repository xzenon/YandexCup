//
//  OverlayView.swift
//  YandexCupTask4
//
//  Created by Xenon on 17.10.2021.
//

import Foundation
import UIKit
import AVFoundation
import Vision

final class OverlayView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with pose: Pose?, _ cameraPosition: AVCaptureDevice.Position? = nil) {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        guard let pose = pose else { return }
        for jointPair in pose.jointPairs {
            let color: UIColor = jointPair.isCorrect ? UIColor.green.withAlphaComponent(0.4) : UIColor.orange.withAlphaComponent(0.4)
            drawStick(with: [jointPair.startPoint, jointPair.endPoint], color: color, cameraPosition: cameraPosition)
        }
    }
    
    func drawStick(with points: [CGPoint], color: UIColor, cameraPosition: AVCaptureDevice.Position?) {
        let path = UIBezierPath(with: points, size: bounds.size)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineCap = .round
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 5.0
        shapeLayer.opacity = 1
        shapeLayer.frame = bounds
        if cameraPosition == .back {
            shapeLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        }
        
        layer.addSublayer(shapeLayer)
    }
}
