# ios-ScrollBar

ScrollBar it is the fast way to scroll through the scroll views, for example table view or collection view.
And it has a small hint view with a text.

<p align="center">
  <img src="https://user-images.githubusercontent.com/12380482/56807579-f5552a00-6837-11e9-9684-037b0ee9d94d.gif" alt="Demo" width="285"/>
</p>

## Installation

Just copy the `ios-ScrollBar/ScrollBar.swift` source file to your project.
Or contact me if you want to install it through CocoaPods or Carthage, I'll make it happen :) Just open an issue.

## Usage

- Create an instance passing a scroll view. ScrollBar retains the scroll view, but don't worry until you don't passing `self` in the init :)
``` swift
self.scrollBar = ScrollBar(scrollView: tableView)
scrollBar.dataSource = self
```
- Add conformance of `ScrollBarDataSource` to your dataSource. All methods are optional and have default implementation, so you can easily check it out in action
``` swift
/// A control view which you drag to scroll. Default is simple grey circle
func view(for scrollBar: ScrollBar) -> UIView
/// Distance between the control view and the right screen edge. Default 30pt
func rightOffset(for scrollBarView: UIView, for scrollBar: ScrollBar) -> CGFloat
/// Position of the hint view by X coordinate. Default is the middle of the scroll view's bounds
func hintViewCenterXCoordinate(for scrollBar: ScrollBar) -> CGFloat
/// A text describing current point in the scroll view. If `nil` the hint view is hidden
func textForHintView(_ hintView: UIView, at point: CGPoint, for scrollBar: ScrollBar) -> String?
```

## Example

You can try to scroll in the demo project `ios-ScrollBar.xcodeproj`

## Requirements
Swift 4.2
iOS 10.3+
