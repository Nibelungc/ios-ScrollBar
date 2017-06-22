//
//  ScrollBar.swift
//  ios-ScrollBar
//
//  Created by Николай Кагала on 22/06/2017.
//  Copyright © 2017 Николай Кагала. All rights reserved.
//

import UIKit

@objc protocol ScrollBarDataSource: class {
    @objc optional func view(for scrollBar: ScrollBar) -> UIView
    @objc optional func rightOffset(for scrollBarView: UIView) -> CGFloat
}

class ScrollBar: NSObject {
    
    private struct Constants {
        static let rightOffset: CGFloat = 30.0
    }
    
    // MARK: - Properties
    
    weak var scrollView: UIScrollView?
    weak var dataSource: ScrollBarDataSource? {
        didSet { reload() }
    }
    
    var scrollBarView: UIView?
    
    let contentOffsetKeyPath = #keyPath(UIScrollView.contentOffset)

    // MARK: - Lifecycle
    
    init(scrollView: UIScrollView) {
        super.init()
        self.scrollView = scrollView
        self.startObservingScrollView()
        self.reload()
    }
    
    deinit {
        stopObservingScrollView()
    }
    
    private func startObservingScrollView() {
        scrollView?.addObserver(self, forKeyPath: contentOffsetKeyPath, options: [.new], context: nil)
    }
    
    private func stopObservingScrollView() {
        scrollView?.removeObserver(self, forKeyPath: contentOffsetKeyPath)
    }
    
    // MARK: - Public
    
    func reload() {
        setupScrollBarView()
    }
    
    // MARK: - Update UI
    
    private func updateScrollBarView(withYOffset offset: CGFloat) {
        guard let scrollBarView = scrollBarView,
            let scrollView = scrollView else { return }
        let rightOffset = dataSource?.rightOffset?(for: scrollBarView) ?? Constants.rightOffset
        let x = scrollView.bounds.maxX - scrollBarView.bounds.width / 2.0 - rightOffset
        let progress = offset / scrollView.contentSize.height
        let y = offset + (scrollView.bounds.height * progress)
        scrollBarView.center = CGPoint(x: x, y: y)
        print("y: \(y), offset: \(offset), progress: \(progress)")
    }
    
    // MARK: - Setup UI
    
    private func setupScrollBarView() {
        self.scrollBarView?.removeFromSuperview()
        guard let scrollView = scrollView else { return }
        let scrollBarView = dataSource?.view?(for: self) ?? createDefaultScrollBarView()
        scrollView.addSubview(scrollBarView)
        self.scrollBarView = scrollBarView
    }
    
    private func createDefaultScrollBarView() -> UIView {
        // TODO: Create view according to design
        let size = CGSize(width: 30, height: 30)
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.layer.cornerRadius = size.width / 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = .red
        return view
    }
    
    // MARK: - Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == contentOffsetKeyPath,
            let change = change,
            let scrollView = scrollView else { return }
        let offset = change[.newKey] as! CGPoint
        let offsetYWithInsets = offset.y + (scrollView.contentInset.top + scrollView.contentInset.bottom)
        updateScrollBarView(withYOffset: offsetYWithInsets)
    }
}
