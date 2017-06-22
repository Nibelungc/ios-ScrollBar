//
//  ViewController.swift
//  ios-ScrollBar
//
//  Created by Николай Кагала on 22/06/2017.
//  Copyright © 2017 Николай Кагала. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    var tableView: UITableView!
    var scrollBar: ScrollBar!
    var items = [String]()
    let identifier = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        items = (0...100).map { "Cell \($0)" }
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        tableView.dataSource = self
        
        scrollBar = ScrollBar(scrollView: tableView)
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}
