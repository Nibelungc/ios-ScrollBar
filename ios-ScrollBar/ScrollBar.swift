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
    @objc optional func textForHintView(_ hintView: UIView, at point: CGPoint, for scrollBar: ScrollBar) -> String?
}

struct HintViewAttributes {
    var minSize: CGSize
    var cornerRadius: CGFloat
    var backgroundColor: UIColor
    var textColor: UIColor
    var font: UIFont
    var textPaddings: CGFloat
    
    init(minSize: CGSize = CGSize(width: 76, height: 32),
         cornerRadius: CGFloat = 5,
         backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3),
         textColor: UIColor = .black,
         font: UIFont = .systemFont(ofSize: 15),
         textPaddings: CGFloat = 8) {
        self.minSize = minSize
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.textPaddings = textPaddings
    }
}

struct ScrollBarAttributes {
    
    var minStartSpeedInPoints: CGFloat
    var rightOffset: CGFloat
    var fadeOutAnimationDuration: TimeInterval
    var fadeOutAnimationDelay: TimeInterval
    
    init(minStartSpeedInPoints: CGFloat = 20.0,
         rightOffset: CGFloat = 30.0,
         fadeOutAnimationDuration: TimeInterval = 0.3,
         fadeOutAnimationDelay: TimeInterval = 0.5) {
        self.minStartSpeedInPoints = minStartSpeedInPoints
        self.rightOffset = rightOffset
        self.fadeOutAnimationDuration = fadeOutAnimationDuration
        self.fadeOutAnimationDelay = fadeOutAnimationDelay
    }
}

class ScrollBar: NSObject {
    
    // MARK: - Public properties
    
    weak var dataSource: ScrollBarDataSource? {
        didSet { reload() }
    }
    private(set) var isFastScrollInProgress = false
    var isHidden: Bool = false
    var showsHintView = true
    var hintViewAttributes = HintViewAttributes() {
        didSet { updateHintViewAttributes() }
    }
    var attributes = ScrollBarAttributes()
    
    // MARK: - Private properties
    
    private var scrollView: UIScrollView
    private var scrollBarView: UIView?
    private var hintView: UILabel? {
        didSet { updateHintViewAttributes() }
    }
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var contentOffsetObserver: NSKeyValueObservation?
    private var fadeOutWorkItem: DispatchWorkItem?
    private var lastPanTranslation: CGFloat = 0.0
    private var isScrollBarActive = false
    private var topBottomInsets: CGFloat {
        var insets = scrollView.contentInset.top + scrollView.contentInset.bottom
        if #available(iOS 11.0, *) {
            insets += scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom
        }
        return insets
    }
    
    // MARK: - Lifecycle
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
        setupObservation()
        reload()
    }
    
    deinit {
        contentOffsetObserver = nil
        scrollBarView?.removeFromSuperview()
        hintView?.removeFromSuperview()
    }
    
    // MARK: - Public
    
    func reload() {
        setupScrollBarView()
    }
    
    // MARK: - Update UI
    
    private func updateScrollBarView(withYOffset offset: CGFloat, speedInPoints speed: CGFloat) {
        guard let scrollBarView = scrollBarView else { return }
        
        guard scrollView.contentSize.height > scrollView.bounds.height, !isHidden else { return }
        bringSubviewsToFrontIfNeeded()
        guard isScrollBarActive ||
            (speed >= attributes.minStartSpeedInPoints) else { return }
        isScrollBarActive = true
        scrollBarView.alpha = 1.0
        let rightOffset = dataSource?.rightOffset?(for: scrollBarView, for: self) ?? attributes.rightOffset
        let x = scrollView.bounds.maxX - scrollBarView.bounds.width - rightOffset
        let insets = topBottomInsets
        let scrollableHeight = scrollView.bounds.height - scrollBarView.bounds.height - insets
        let offsetWithInsets = offset + insets
        let progress = offsetWithInsets / (scrollView.contentSize.height - scrollView.bounds.height + insets)
        let y = offsetWithInsets + (scrollableHeight * progress)
        scrollBarView.frame.origin = CGPoint(x: x, y: y)
        updateHintView(forScrollBarView: scrollBarView)
        scheduleFadeOutAnimation()
    }
    
    private func updateHintView(forScrollBarView scrollBarView: UIView) {
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
        
        if let text = dataSource?.textForHintView?(_hintView, at: point, for: self) {
            _hintView.text = text
            var size = _hintView.sizeThatFits(hintViewAttributes.minSize)
            size.width += hintViewAttributes.textPaddings * 2
            size.width = max(hintViewAttributes.minSize.width, size.width)
            size.height = max(hintViewAttributes.minSize.height, size.height)
            _hintView.frame.size = size
            _hintView.center = point
        } else {
            hintView?.alpha = 0.0
        }
    }
    
    // MARK: - Setup UI
    
    private func setupScrollBarView() {
        removeOldScrollBar()
        let scrollBarView = dataSource?.view?(for: self) ?? createDefaultScrollBarView()
        scrollBarView.isUserInteractionEnabled = true
        scrollView.addSubview(scrollBarView)
        scrollBarView.alpha = 0.0
        self.scrollBarView = scrollBarView
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        scrollBarView.addGestureRecognizer(gestureRecognizer)
        scrollView.panGestureRecognizer.require(toFail: gestureRecognizer)
    }
    
    private func setupHintView() {
        guard hintView == nil else { return }
        let _hintView = createDefaultScrollBarHintView()
        scrollView.addSubview(_hintView)
        _hintView.alpha = 0.0
        _hintView.isUserInteractionEnabled = false
        hintView = _hintView
    }
    
    private func createDefaultScrollBarView() -> UIView {
        let size = CGSize(width: 48, height: 48)
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.layer.cornerRadius = size.width / 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }
    
    private func createDefaultScrollBarHintView() -> UILabel {
        let label = UILabel(frame: .zero)
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }
    
    // MARK: - Actions
    
    @objc private func panGestureAction(gesture: UIPanGestureRecognizer) {
        guard let scrollBarView = scrollBarView else { return }
        switch gesture.state {
        case .began:
            lastPanTranslation = 0.0
            isFastScrollInProgress = true
        case .changed:
            let insets = topBottomInsets
            let deltaY = gesture.translation(in: scrollView).y - lastPanTranslation
            lastPanTranslation = gesture.translation(in: scrollView).y
            let scrollableHeight = scrollView.bounds.height - scrollBarView.bounds.height - insets
            let contentHeight = scrollView.contentSize.height - scrollView.bounds.height + insets
            let maxYOffset = scrollView.contentSize.height - scrollView.bounds.height
            let deltaContentY = deltaY * (contentHeight / scrollableHeight)
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
    
    private func setupObservation() {
        contentOffsetObserver = scrollView.observe(\.contentOffset, options: [.new, .old]) {
            [unowned self] _, change in
            
            guard let newOffset = change.newValue,
                let oldOffset = change.oldValue else { return }
            let speedInPoints = abs(oldOffset.y - newOffset.y)
            self.updateScrollBarView(withYOffset: newOffset.y, speedInPoints: speedInPoints)
        }
    }
    
    private func scheduleFadeOutAnimation() {
        let views = [scrollBarView, hintView]
        fadeOutWorkItem?.cancel()
        fadeOutWorkItem = DispatchWorkItem {
            [weak self] in
            
            guard let sSelf = self else { return }
            guard !sSelf.isFastScrollInProgress else { return }
            UIView.animate(withDuration: sSelf.attributes.fadeOutAnimationDuration) {
                views.forEach { $0?.alpha = 0.0 }
                sSelf.isScrollBarActive = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + attributes.fadeOutAnimationDelay,
                                      execute: fadeOutWorkItem!)
    }
    
    private func removeOldScrollBar() {
        guard let oldScrollBarView = scrollBarView else { return }
        oldScrollBarView.removeFromSuperview()
        if let oldGesture = panGestureRecognizer {
            oldScrollBarView.removeGestureRecognizer(oldGesture)
        }
    }
    
    private func updateHintViewAttributes() {
        guard let hintView = hintView else { return }
        hintView.backgroundColor = hintViewAttributes.backgroundColor
        hintView.layer.cornerRadius = hintViewAttributes.cornerRadius
        hintView.frame.size = hintViewAttributes.minSize
        hintView.textColor = hintViewAttributes.textColor
        hintView.font = hintViewAttributes.font
    }
    
    private func bringSubviewsToFrontIfNeeded() {
        let views = [hintView, scrollBarView].compactMap { $0 }
        views.forEach { scrollView.bringSubview(toFront: $0) }
    }
}
