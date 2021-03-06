//
//  ViewController.swift
//  ios-ScrollBar
//
//  Created by Николай Кагала on 22/06/2017.
//  Copyright © 2017 Николай Кагала. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, ScrollBarDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var scrollBar: ScrollBar!
    private var items = [[String]]()
    private let identifier = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reload()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        tableView.sectionHeaderHeight = 20
        
        scrollBar = ScrollBar(scrollView: tableView)
        scrollBar.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadAction))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(shortListAction))
    }
    
    func reloadAction() {
        reload()
    }
    
    func shortListAction() {
        reload(max: 5)
    }
    
    func reload(min: Int = 0, max: Int = 10_000) {
        let maxCount = min + Int(arc4random_uniform(UInt32(max - min + 1)))
        items = [
            (0...maxCount).map { "Cell \($0)" },
            (0...maxCount).map { "Cell \($0)" },
            (0...maxCount).map { "Cell \($0)" }
        ]
        navigationItem.title = "\(maxCount) Cells"
        tableView?.reloadData()
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
