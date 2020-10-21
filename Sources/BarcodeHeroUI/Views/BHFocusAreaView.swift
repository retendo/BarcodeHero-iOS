// Copyright © 2020 SpotHero, Inc. All rights reserved.

#if !os(watchOS) && canImport(UIKit)
    
    import Foundation
    import UIKit
    
    @available(iOS 9.0, *)
    class BHFocusAreaView: UIView {
        // MARK: Constants
        
        private static let cutoutHeight: CGFloat = 144
        private static let labelWidth: CGFloat = 216
        
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
        
        init() {
            super.init(frame: .zero)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = 16
            
            stackView.addArrangedSubview(self.cutoutView)
            stackView.addArrangedSubview(self.helpLabel)
            
            self.addSubview(stackView)
            
            cutoutView.heightAnchor.constraint(equalToConstant: Self.cutoutHeight).isActive = true
            cutoutView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 32).isActive = true
            cutoutView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -32).isActive = true
            
            helpLabel.widthAnchor.constraint(equalToConstant: Self.labelWidth).isActive = true
            
            NSLayoutConstraint.activate([
                // Activate height and width constraints for this view
                self.heightAnchor.constraint(equalTo: stackView.heightAnchor),
                self.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                // Activate pinning constraints for the embedded stack view
                stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: self.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
        }
        
        required convenience init?(coder: NSCoder) {
            self.init()
        }
    }
    
#endif
