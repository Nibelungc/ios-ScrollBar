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
    @objc optional func rightOffset(for scrollBarView: UIView, for scrollBar: ScrollBar) -> CGFloat
    
    @objc optional func hintViewCenterXCoordinate(for scrollBar: ScrollBar) -> CGFloat
    @objc optional func textForHintView(_ hintView: UIView, at point: CGPoint, for scrollBar: ScrollBar) -> String
}


class ScrollBar: NSObject {
    
    private struct Constants {
        static let rightOffset: CGFloat = 30.0
        static let fadeOutAnimationDuration = 0.3
        static let fadeOutAnimationDelay = 0.5
        static let defaultScrollBarViewSize = CGSize(width: 48, height: 48)
        static let hintViewSize = CGSize(width: 76, height: 32)
        static let hintViewCornerRadius: CGFloat = 5
        static let hintViewBackgroundColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    // MARK: - Public properties
    
    weak var dataSource: ScrollBarDataSource? {
        didSet { reload() }
    }
    private(set) var isFastScrollInProgress = false
    var showsHintView = true
    
    // MARK: - Private properties
    
    weak private var scrollView: UIScrollView?
    private var scrollBarView: UIView?
    private var hintView: UILabel?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private let contentOffsetKeyPath = #keyPath(UIScrollView.contentOffset)
    private var fadeOutWorkItem: DispatchWorkItem?
    private var lastPanTranslation: CGFloat = 0.0

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
        scrollBarView.alpha = 1.0
        let rightOffset = dataSource?.rightOffset?(for: scrollBarView, for: self) ?? Constants.rightOffset
        let x = scrollView.bounds.maxX - scrollBarView.bounds.width - rightOffset
        let insets = scrollView.contentInset.top + scrollView.contentInset.bottom
        let scrollableHeight = scrollView.bounds.height - scrollBarView.bounds.height - insets
        let offsetWithInsets = offset + insets
        let progress = offsetWithInsets / (scrollView.contentSize.height - scrollView.bounds.height + insets)
        let y = offsetWithInsets + (scrollableHeight * progress)
        scrollBarView.frame.origin = CGPoint(x: x, y: y)
        updateHintView(forScrollBarView: scrollBarView)
        scheduleFadeOutAnimation()
    }
    
    private func updateHintView(forScrollBarView scrollBarView: UIView) {
        guard let scrollView = scrollView else { return }
        hintView?.alpha = (showsHintView && isFastScrollInProgress) ? 1.0 : 0.0
        guard showsHintView else { return }
        if hintView == nil {
            setupHintView()
        }
        let _hintView = hintView!
        let defaultXCoordinate = scrollView.bounds.midX
        let x = dataSource?.hintViewCenterXCoordinate?(for: self) ?? defaultXCoordinate
        let y = scrollBarView.center.y
        let point = CGPoint(x: x, y: y)
        _hintView.text = dataSource?.textForHintView?(_hintView, at: point, for: self)
        var size = _hintView.sizeThatFits(Constants.hintViewSize)
        size.width = max(Constants.hintViewSize.width, size.width)
        size.height = max(Constants.hintViewSize.height, size.height)
        _hintView.frame.size = size
        _hintView.center = point
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
        scrollView.panGestureRecognizer.require(toFail: gestureRecognizer)
    }
    
    private func setupHintView() {
        guard let scrollView = scrollView,
            hintView == nil else { return }
        let _hintView = createDefaultScrollBarHintView()
        scrollView.addSubview(_hintView)
        _hintView.isUserInteractionEnabled = false
        hintView = _hintView
    }
    
    private func createDefaultScrollBarView() -> UIView {
        let size = Constants.defaultScrollBarViewSize
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.layer.cornerRadius = size.width / 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }
    
    private func createDefaultScrollBarHintView() -> UILabel {
        let label = UILabel(frame: CGRect(origin: .zero, size: Constants.hintViewSize))
        label.backgroundColor = Constants.hintViewBackgroundColor
        label.layer.cornerRadius = Constants.hintViewCornerRadius
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }
    
    // MARK: - Actions
    
    dynamic private func panGestureAction(gesture: UIPanGestureRecognizer) {
        guard let scrollView = scrollView else { return }
        guard let scrollBarView = scrollBarView else { return }
        switch gesture.state {
        case .began:
            lastPanTranslation = 0.0
            isFastScrollInProgress = true
        case .changed:
            let insets = scrollView.contentInset.top + scrollView.contentInset.bottom
            let scrollableHeight = scrollView.bounds.height - scrollBarView.bounds.height - insets
            let deltaY = gesture.translation(in: scrollView).y - lastPanTranslation
            lastPanTranslation = gesture.translation(in: scrollView).y
            let maxYOffset = scrollView.contentSize.height - scrollView.bounds.height
            let deltaContentY = deltaY * (maxYOffset / scrollableHeight)
            var y = scrollView.contentOffset.y + deltaContentY
            y = max(-insets, (min(maxYOffset, y)))
            let newOffset = CGPoint(x: scrollView.contentOffset.x, y: y)
            scrollView.setContentOffset(newOffset, animated: false)
        case .ended, .cancelled, .failed:
            isFastScrollInProgress = false
        default:
            return
        }
    }
    
    // MARK: - Private
    
    private func scheduleFadeOutAnimation() {
        let views = [scrollBarView, hintView]
        fadeOutWorkItem?.cancel()
        fadeOutWorkItem = DispatchWorkItem() {
            UIView.animate(withDuration: Constants.fadeOutAnimationDuration) {
                views.forEach { $0?.alpha = 0.0 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.fadeOutAnimationDelay,
                                      execute: fadeOutWorkItem!)
    }
    
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
            let change = change else { return }
        let offset = change[.newKey] as! CGPoint
        updateScrollBarView(withYOffset: offset.y)
    }
}
