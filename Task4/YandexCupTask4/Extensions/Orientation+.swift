//
//  Orientation+.swift
//  YandexCupTask4
//
//  Created by Xenon on 19.10.2021.
//

import UIKit
import AVFoundation

extension CGImagePropertyOrientation {
    init(frontCamera: Bool, deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation) {
        switch deviceOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = frontCamera ? .down : .up
        case .landscapeRight:
            self = frontCamera ? .up : .down
        default:
            self = .right
        }
    }
}

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeLeft
        case .landscapeLeft: return .landscapeRight
        case .portrait: return .portrait
        default: return nil
        }
    }
}
