//
//  TimeInterval+.swift
//  YandexCupTask4
//
//  Created by Xenon on 18.10.2021.
//

import Foundation

extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        var formatString = ""
        
        if hours == 0 {
            formatString = "%0.2d:%0.2d"
            return String(format: formatString, minutes, seconds)
        } else {
            formatString = "%2d:%0.2d:%0.2d"
            return String(format: formatString,hours,minutes,seconds)
        }
    }
}
