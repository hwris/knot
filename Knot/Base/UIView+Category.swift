//
//  UIView+DynamicColor.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/4.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable
    var darkBackgroundColor: UIColor? {
        get {
            return backgroundColor?.resolvedColor(with: .dark)
        }
        
        set {
            guard let dark = newValue else {
                return
            }
            
            let lightColor = backgroundColor ?? dark
            backgroundColor = UIColor(dark, lightColor)
        }
    }
    
    @IBInspectable
    var darkTintColor: UIColor? {
        get {
            return tintColor?.resolvedColor(with: .dark)
        }
        
        set {
            guard let dark = newValue else {
                return
            }
            
            let lightColor = tintColor ?? dark
            tintColor = UIColor(dark, lightColor)
        }
    }
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return layer.borderColor.map({ UIColor(cgColor: $0) })
        }
        
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            return layer.shadowColor.map({ UIColor(cgColor: $0) })
        }
        
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var darkShadowColor: UIColor? {
        get {
            return shadowColor?.resolvedColor(with: .dark)
        }
        
        set {
            guard let dark = newValue else {
                return
            }
            
            let lightColor = shadowColor ?? dark
            shadowColor = UIColor(dark, lightColor)
        }
    }
}

extension UILabel {
    @IBInspectable
    var darkTextColor: UIColor? {
        get {
            return textColor?.resolvedColor(with: .dark)
        }
        
        set {
            guard let dark = newValue else {
                return
            }
            
            let lightColor = textColor ?? dark
            textColor = UIColor(dark, lightColor)
        }
    }
}

extension UITextView {
    @IBInspectable
    var darkTextColor: UIColor? {
        get {
            return textColor?.resolvedColor(with: .dark)
        }
        
        set {
            guard let dark = newValue else {
                return
            }
            
            let lightColor = textColor ?? dark
            textColor = UIColor(dark, lightColor)
        }
    }
}

extension UIControl.State {
    public static private(set) var selectedHighlighted: UIControl.State = [ .selected, .highlighted ]
}

extension UIButton {
    
    @IBInspectable
    var selectedHighlightedImage: UIImage? {
        get {
            return image(for: .selectedHighlighted)
        }
        
        set {
            setImage(newValue, for: .selectedHighlighted)
        }
    }
    
    @IBInspectable
    var selectedHighlightedTitleColor: UIColor? {
        get {
            return titleColor(for: .selectedHighlighted)
        }
        
        set {
            setTitleColor(newValue, for: .selectedHighlighted)
        }
    }
    
    @IBInspectable
    var selectedHighlightedBackgroundImage: UIImage? {
        get {
            return backgroundImage(for: .selectedHighlighted)
        }
        
        set {
            setBackgroundImage(newValue, for: .selectedHighlighted)
        }
    }
    
    @IBInspectable
    var selectedHighlightedTitle: String? {
        get {
            return title(for: .selectedHighlighted)
        }
        
        set {
            setTitle(newValue, for: .selectedHighlighted)
        }
    }
}

class KNOTButton: UIButton {
    private var backgroundImageDynamicProvider: (UIControl.State, (KNOTUserInterfaceStyle) -> UIImage?)?
    
    func setBackgroundImage(dynamicProvider: @escaping (KNOTUserInterfaceStyle) -> UIImage?, for state: UIControl.State) {
        if #available(iOS 12.0, *) {
            setBackgroundImage(dynamicProvider(KNOTUserInterfaceStyle(rawValue: traitCollection.userInterfaceStyle.rawValue) ?? .unspecified), for: state)
        } else {
            setBackgroundImage(dynamicProvider(.unspecified), for: state)
        }
        
        backgroundImageDynamicProvider = (state, dynamicProvider)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let _backgroundImageDynamicProvider = backgroundImageDynamicProvider {
                    setBackgroundImage(dynamicProvider: _backgroundImageDynamicProvider.1, for: _backgroundImageDynamicProvider.0)
                }
            }
        }
    }
}

extension UIView {
    func setRoundCorners(frome point: CGPoint) {
        setRoundCorners(point == .zero ? nil : UIRectCorner(rawValue: UInt(point.x)), cornerRadii: point.y)
    }
    
    func setRoundCorners(_ roundCorners: UIRectCorner?, cornerRadii: CGFloat) {
        guard let corners = roundCorners else {
            layer.mask = nil
            return
        }
        
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: cornerRadii, height: cornerRadii))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}

class KNOTRoundCornersView : UIView {
    @IBInspectable
    private var roundingCorners: CGPoint = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setRoundCorners(frome: roundingCorners)
    }
}

class KNOTRoundCornersTableView: UITableView {
    @IBInspectable
    private var roundingCorners: CGPoint = .zero {
        didSet {
            if oldValue != .zero && oldValue != roundingCorners {
                setNeedsLayout()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setRoundCorners(frome: roundingCorners)
    }
}
