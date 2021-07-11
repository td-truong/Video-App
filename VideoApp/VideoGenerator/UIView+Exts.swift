//
//  UIView+Exts.swift
//  VideoApp
//
//  Created by Duy Truong on 08/07/2021.
//

import UIKit

extension UIView {
    func shotImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }    
}
