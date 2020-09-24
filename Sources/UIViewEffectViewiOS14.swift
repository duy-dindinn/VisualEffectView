//
//  UIViewEffectViewiOS14.swift
//  VisualEffectView
//
//  Created by Lasha Efremidze on 9/14/20.
//

import UIKit


protocol PropertyStoring {
    associatedtype T
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T
}
extension PropertyStoring {
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        return value
    }
}


@available(iOS 14, *)
extension UIVisualEffectView: PropertyStoring {
    typealias T = UIBlurEffect.Style
    
    var ios14_blurRadius: CGFloat {
        get {
            return gaussianBlur?.requestedValues?["inputRadius"] as? CGFloat ?? 0
        }
        set {
            prepareForChanges()
            gaussianBlur?.requestedValues?["inputRadius"] = newValue
            applyChanges()
        }
    }
    var ios14_colorTint: UIColor? {
        get {
            return sourceOver?.value(forKeyPath: "color") as? UIColor
        }
        set {
            prepareForChanges()
            sourceOver?.setValue(newValue, forKeyPath: "color")
            sourceOver?.perform(Selector(("applyRequestedEffectToView:")), with: overlayView)
            applyChanges()
        }
    }
    
    private struct CustomProperties {
        static var blurEffectStyle = UIBlurEffect.Style.dark
    }
    
    var blurEffectStyle: UIBlurEffect.Style {
        get {
            return getAssociatedObject(&CustomProperties.blurEffectStyle, defaultValue: CustomProperties.blurEffectStyle)
        }
        set {
            return objc_setAssociatedObject(self, &CustomProperties.blurEffectStyle, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open func setBlurEffectStyle(_ style: UIBlurEffect.Style) {
        blurEffectStyle = style
    }
}

private extension UIVisualEffectView {
    var backdropView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectBackdropView"))
    }
    var overlayView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectSubview"))
    }
    var gaussianBlur: NSObject? {
        return backdropView?.value(forKey: "filters", withFilterType: "gaussianBlur")
    }
    var sourceOver: NSObject? {
        return overlayView?.value(forKey: "viewEffects", withFilterType: "sourceOver")
    }
    func prepareForChanges() {
        if #available(iOS 14, *) {
            self.effect = UIBlurEffect(style: blurEffectStyle)
        } else {
            // Fallback on earlier versions
        }
        gaussianBlur?.setValue(1.0, forKeyPath: "requestedScaleHint")
    }
    func applyChanges() {
        backdropView?.perform(Selector(("applyRequestedFilterEffects")))
    }
}

private extension NSObject {
    var requestedValues: [String: Any]? {
        get { return value(forKeyPath: "requestedValues") as? [String: Any] }
        set { setValue(newValue, forKeyPath: "requestedValues") }
    }
    func value(forKey key: String, withFilterType filterType: String) -> NSObject? {
        return (value(forKeyPath: key) as? [NSObject])?.first { $0.value(forKeyPath: "filterType") as? String == filterType }
    }
}

private extension UIView {
    func subview(of classType: AnyClass?) -> UIView? {
        return subviews.first { type(of: $0) == classType }
    }
}
