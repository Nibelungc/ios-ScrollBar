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
    
    // MARK: - Public properties
    
    weak var dataSource: ScrollBarDataSource? {
        didSet { reload() }
    }
    
    // MARK: - Private properties
    
    weak private var scrollView: UIScrollView?
    private var scrollBarView: UIView?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private let contentOffsetKeyPath = #keyPath(UIScrollView.contentOffset)
    private var panInProgress = false

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
        let x = scrollView.bounds.maxX - scrollBarView.bounds.width - rightOffset
        let insets = scrollView.contentInset.top + scrollView.contentInset.bottom
        let scrollableHeight = scrollView.bounds.height - scrollBarView.bounds.height - insets
        let offsetWithInsets = offset + insets
        let progress = offsetWithInsets / (scrollView.contentSize.height - scrollView.bounds.height + insets)
        print(progress)
        let y = offsetWithInsets + (scrollableHeight * progress)
        scrollBarView.frame.origin = CGPoint(x: x, y: y)
    }
    
    // MARK: - Setup UI
    
    private func setupScrollBarView() {
        removeOldScrollBar()
        guard let scrollView = scrollView else { return }
        let scrollBarView = dataSource?.view?(for: self) ?? createDefaultScrollBarView()
        scrollView.addSubview(scrollBarView)
        self.scrollBarView = scrollBarView
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        scrollBarView.addGestureRecognizer(gestureRecognizer)
    }
    
    private func createDefaultScrollBarView() -> UIView {
        // TODO: Create view according to design
        let size = CGSize(width: 40, height: 40)
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.layer.cornerRadius = size.width / 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = .red
        return view
    }
    
    // MARK: - Actions
    
    dynamic private func panGestureAction(gesture: UIPanGestureRecognizer) {
        guard let scrollView = scrollView else { return }
        guard let scrollBarView = scrollBarView else { return }
        switch gesture.state {
        case .began:
            panInProgress = true
        case .changed:
            let pointInScrollView = gesture.location(in: scrollView.superview!).y - scrollView.contentInset.top
            print(pointInScrollView)
            let progress = pointInScrollView / scrollView.bounds.height
            var y = pointInScrollView + (scrollView.contentSize.height * progress)
            y = min(scrollView.contentSize.height - scrollView.bounds.height, y)
            let newOffset = CGPoint(x: scrollView.contentOffset.x, y: max(0, y))
            scrollView.setContentOffset(newOffset, animated: false)
        case .ended, .cancelled, .failed:
            panInProgress = false
        default:
            return
        }
    }
    
    // MARK: - Private
    
    private func removeOldScrollBar() {
        guard let oldScrollBarView = scrollBarView else { return }
        oldScrollBarView.removeFromSuperview()
        if let oldGesture = panGestureRecognizer {
            oldScrollBarView.removeGestureRecognizer(oldGesture)
        }
    }
    
    // MARK: - Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == contentOffsetKeyPath,
            let change = change,
            let scrollView = scrollView else { return }
//        guard !panInProgress else { return }
        let offset = change[.newKey] as! CGPoint
        updateScrollBarView(withYOffset: offset.y)
    }
}
