//
//  CGPoint+.swift
//  YandexCupTask4
//
//  Created by Xenon on 18.10.2021.
//

import UIKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
