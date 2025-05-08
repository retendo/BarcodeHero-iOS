// Copyright © 2020 SpotHero, Inc. All rights reserved.

#if !os(watchOS) && canImport(UIKit)
    
    import Foundation
    import UIKit
    
    @available(iOS 9.0, *)
    class BHFocusAreaView: UIView {
        // MARK: Properties - Views
        
        private(set) lazy var helpLabel: UILabel = {
            let typeLabel = UILabel()
            typeLabel.textAlignment = .center
            typeLabel.translatesAutoresizingMaskIntoConstraints = false
            typeLabel.numberOfLines = 0
            
            return typeLabel
        }()
        
        private(set) lazy var cutoutView: UIView = {
            let cutoutView = UIView()
            cutoutView.translatesAutoresizingMaskIntoConstraints = false
            cutoutView.layer.cornerRadius = 0
            cutoutView.layer.masksToBounds = true
            
            return cutoutView
        }()
        
        // MARK: Methods - Lifecycle
        
        init(cutoutHeight: CGFloat = 144, maxLabelWidth: CGFloat = 300) {
            super.init(frame: .zero)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(self.cutoutView)
            self.addSubview(self.helpLabel)
            
            NSLayoutConstraint.activate([
                // Vertical constraints
                cutoutView.topAnchor.constraint(equalTo: self.topAnchor),
                cutoutView.heightAnchor.constraint(equalToConstant: cutoutHeight),
                helpLabel.topAnchor.constraint(equalTo: cutoutView.bottomAnchor, constant: 16),
                helpLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                
                // Horizontal constraints
                cutoutView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 32),
                cutoutView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -32),
                
                helpLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                helpLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxLabelWidth),
                helpLabel.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, constant: -32)
            ])
        }
        
        required convenience init?(coder: NSCoder) {
            self.init()
        }
    }
    
#endif
