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
        
        static func animateWithDisplayLink(duration: CGFloat, animationHandler: @escaping PercentBasedAnimationHandler, completionHandler: AnimationCompletionHandler?) {
            let handler = AnimationDisplayLink()
            handler.animationDuration = duration
            handler.animationHandler = animationHandler
            handler.completionHandler = completionHandler
            handler.startAnimation()
        }
    }

    /// Animations
    typealias PercentBasedAnimationHandler = ((_ percent: CGFloat) -> Void)
    typealias AnimationCompletionHandler = (() -> Void)

    class AnimationDisplayLink: NSObject {
        var animationDuration: CGFloat = 0.3

        var animationHandler: PercentBasedAnimationHandler!
        var completionHandler: AnimationCompletionHandler?

        var startTime: CFAbsoluteTime!

        var displayLink: CADisplayLink!

        func startAnimation() {
            self.startTime = CFAbsoluteTimeGetCurrent()
            self.displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(displayLink:)))
            self.displayLink.add(to: RunLoop.main, forMode: .common)
        }

        func stopAnimation() {
            self.displayLink.invalidate()
            self.displayLink = nil
        }

        @objc func handleDisplayLink(displayLink: CADisplayLink) {
            let elapsed = CFAbsoluteTimeGetCurrent() - self.startTime
            let percent = CGFloat(elapsed) / animationDuration

            if percent >= 1.0 {
                stopAnimation()
                self.animationHandler(1.0)
                self.completionHandler?()
            } else {
                self.animationHandler(percent)
            }
        }
    }
    
#endif
