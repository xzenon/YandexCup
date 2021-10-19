//
//  ViewController.swift
//  YandexCupTask4
//
//  Created by Xenon on 17.10.2021.
//

import UIKit

protocol RecorderDelegate {
    func addNew(record: Record)
}

class ViewController: UITableViewController {

    private let storage = Storage()
    private var records: [Record] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy HH:mm:ss"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Plank recorder"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New record",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(buttonDidPress(button:)))
        
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        records = storage.records ?? []
    }
    
    // MARK: - Actions
    
    @objc
    private func buttonDidPress(button _: UIBarButtonItem) {
        let vc = CameraViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Duration: \(records[indexPath.item].duration.stringFromTimeInterval())"
        cell.detailTextLabel?.text = dateFormatter.string(from: records[indexPath.item].date)
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Delete record", message: "Do you want to delete this record?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
            self.records.remove(at: indexPath.item)
            self.storage.records = self.records
            self.tableView.reloadData()            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: RecorderDelegate {
    
    func addNew(record: Record) {
        records.insert(record, at: 0)
        storage.records = records
        tableView.reloadData()
        print("Record: \(record)")
    }
}
