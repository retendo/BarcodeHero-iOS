// Copyright © 2020 SpotHero, Inc. All rights reserved.

#if !os(watchOS) && canImport(UIKit)
    
    import AVFoundation
    import Foundation
    import UIKit
    
    extension UIView {
        func mask(_ maskRect: CGRect, invert: Bool = false, cornerRadius: CGFloat) {
            let maskLayer = CAShapeLayer()
            let path = CGMutablePath()
            
            if invert {
                path.addRect(bounds)
            }
            
            path.addRoundedRect(in: maskRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
            
            maskLayer.path = path
            
            if invert {
                maskLayer.fillRule = .evenOdd
            }
            
            layer.mask = maskLayer
        }
    }
    
#endif
