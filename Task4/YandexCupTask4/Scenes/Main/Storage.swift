//
//  Storage.swift
//  YandexCupTask4
//
//  Created by Xenon on 19.10.2021.
//

import Foundation

struct Record: Codable {
    var duration: TimeInterval
    var date: Date
}

class Storage {
    
    private let userDefaults = UserDefaults.standard
    private let userDefaultsKey = "RecordsKey"
    
    var records: [Record]? {
        get {
            if let data = userDefaults.data(forKey: userDefaultsKey),
               let records = try? PropertyListDecoder().decode(Array<Record>.self, from: data) {
                return records
            }
            return nil
        }
        set {
            if let newValue = newValue {
                do {
                    let data = try PropertyListEncoder().encode(newValue)
                    userDefaults.set(data, forKey: userDefaultsKey)
                } catch {
                    print("Unable to encode records data: \(error)")
                }
            } else {
                userDefaults.removeObject(forKey: userDefaultsKey)
            }
            userDefaults.synchronize()
        }
    }
}
