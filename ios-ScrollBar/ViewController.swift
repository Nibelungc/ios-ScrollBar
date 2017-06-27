//
//  ViewController.swift
//  ios-ScrollBar
//
//  Created by Николай Кагала on 22/06/2017.
//  Copyright © 2017 Николай Кагала. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, ScrollBarDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var scrollBar: ScrollBar!
    var items = [[String]]()
    let identifier = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        items = [
            (0...1000).map { "Cell \($0)" },
            (0...1000).map { "Cell \($0)" },
            (0...1000).map { "Cell \($0)" }
        ]
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderHeight = 20
        
        scrollBar = ScrollBar(scrollView: tableView)
        scrollBar.dataSource = self
    }
    
    // MARK - ScrollBarDataSource
    
    func textForHintView(_ hintView: UIView, at point: CGPoint, for scrollBar: ScrollBar) -> String? {
        guard let indexPath = tableView.indexPathForRow(at: point) else { return nil }
        let title = items[indexPath.section][indexPath.row]
        return title
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = items[indexPath.section][indexPath.row]
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .groupTableViewBackground
        return view
    }
}
