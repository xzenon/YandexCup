//
//  CustomViewCell.swift
//  YandexCupTask4
//
//  Created by Xenon on 19.10.2021.
//

import UIKit

final class TableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        textLabel?.font = UIFont.systemFont(ofSize: 16)
        textLabel?.textColor = .black
        detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        detailTextLabel?.textColor = .gray
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.lightGray
        selectedBackgroundView = backgroundView
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
