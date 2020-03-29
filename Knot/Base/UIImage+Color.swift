//
//  UIImage+Color.swift
//  Knot
//
//  Created by 苏杨 on 2020/3/29.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import UIKit

public extension UIImage {
    class func fromColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func fromColor(color: UIColor, cornerRadius: CGFloat = 1.0) -> UIImage? {
        let size = CGSize(width: cornerRadius * 2, height: cornerRadius * 2)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let bezierPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        color.setFill()
        bezierPath.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image?.resizableImage(withCapInsets: UIEdgeInsets(top: cornerRadius,
                                                                 left: cornerRadius,
                                                                 bottom: cornerRadius,
                                                                 right: cornerRadius))
    }
}
