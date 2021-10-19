//
//  UIBezierPath+.swift
//  YandexCupTask4
//
//  Created by Xenon on 18.10.2021.
//

import UIKit

extension UIBezierPath {
    convenience init(with points: [CGPoint], size: CGSize) {
        self.init()
        let availablePoints = points.filter{( $0.x != 0.0 && $0.y != 1.0 )}
        for (index, point) in availablePoints.enumerated() {
            index == 0 ? self.move(to: point) : self.addLine(to: point)
        }
        apply(CGAffineTransform.identity.scaledBy(x: size.width, y: size.height))
        apply(CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -size.width, y: -size.height))
    }
}
