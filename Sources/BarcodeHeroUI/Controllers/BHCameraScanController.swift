// Copyright © 2020 SpotHero, Inc. All rights reserved.

#if !os(watchOS) && canImport(UIKit)
    
    import AVFoundation
    import Foundation
    import UIKit
    
    #warning("TODO: Make the controller work well in any orientation.")
    
    @available(iOS 9.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    open class BHCameraScanController: UIViewController {
        // MARK: Properties
        
        private lazy var backgroundView: UIView = {
            let backgroundView = UIView(frame: UIScreen.main.bounds)
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            
            self.view.addSubview(backgroundView)
            
            if #available(iOS 11.0, tvOS 11.0, *) {
                NSLayoutConstraint.activate([
                    backgroundView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                    backgroundView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                    backgroundView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                    backgroundView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    backgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor),
                    backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                ])
            }
            
            return backgroundView
        }()
        
        private lazy var focusAreaView: BHFocusAreaView = {
            let focusAreaView = BHFocusAreaView()
            
            self.view.addSubview(focusAreaView)
            
            NSLayoutConstraint.activate([
                focusAreaView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                focusAreaView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -48),
            ])
            
            return focusAreaView
        }()
        
        private let session = AVCaptureSession()
        
        private let sessionQueue = DispatchQueue(label: "barcodehero.capturesession")
        
//    private var dismissOnScan: Bool = false
        private var hasLoaded: Bool = false
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private lazy var curtain: UIView = {
            let curtain = UIView(frame: UIScreen.main.bounds)
            curtain.backgroundColor = UIColor.black
            
            self.view.addSubview(curtain)
            
            if #available(iOS 11.0, tvOS 11.0, *) {
                NSLayoutConstraint.activate([
                    curtain.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                    curtain.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                    curtain.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                    curtain.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    curtain.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    curtain.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    curtain.topAnchor.constraint(equalTo: self.view.topAnchor),
                    curtain.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                ])
            }
            
            return curtain
        }()
//    private var startingBarTintColor: UIColor?
//    private var startingTintColor: UIColor?
        
        private var helpText: String = "Focus the barcode inside\nthe rectangle above"
        private var helpTextColor: UIColor = .white
        private var helpTextFont: UIFont = .systemFont(ofSize: 20, weight: .regular)
        private var cutoutCornerRadius: CGFloat = 4.0
        
        private let metadataOutput = AVCaptureMetadataOutput()
        
        private var isEvolving = false
        
        public weak var delegate: BHCameraScanControllerDelegate?
        
        // MARK: Methods - Initializers
        
        public init(helpText: String? = nil,
                    helpTextColor: UIColor? = nil,
                    helpTextFont: UIFont? = nil,
                    cutoutCornerRadius: CGFloat? = nil) {
            if let helpText = helpText { self.helpText = helpText }
            if let helpTextColor = helpTextColor { self.helpTextColor = helpTextColor }
            if let helpTextFont = helpTextFont { self.helpTextFont = helpTextFont }
            if let cutoutCornerRadius = cutoutCornerRadius { self.cutoutCornerRadius = cutoutCornerRadius }
            
            super.init(nibName: nil, bundle: nil)
        }
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        // MARK: Methods - Lifecycle
        
        override open func viewDidLoad() {
            super.viewDidLoad()
            
            if let device = AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device) {
                try? device.lockForConfiguration()
                
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isAutoFocusRangeRestrictionSupported {
                    device.autoFocusRangeRestriction = .near
                }
                
                device.unlockForConfiguration()
                
                self.session.addInput(input)
            }
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce]
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            self.focusAreaView.helpLabel.font = helpTextFont
            self.focusAreaView.helpLabel.textColor = helpTextColor
            
            startCapturing()
        }
        
        override open func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            edgesForExtendedLayout = UIRectEdge.all
            
            startCapturing()
            
            isEvolving = false
            self.focusAreaView.helpLabel.text = helpText
            
            self.curtain.alpha = 1
            UIView.animate(withDuration: 0.5, delay: 0.3, animations: {
                self.curtain.alpha = 0
            })
            
            guard !self.hasLoaded else {
                let cutoutView = self.focusAreaView.cutoutView
                let cutoutFrame = cutoutView.convert(cutoutView.bounds, to: self.view)
                self.backgroundView.mask(cutoutFrame, invert: true, cornerRadius: self.cutoutCornerRadius)
                return
            }
        }
        
        override open func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            guard !self.hasLoaded else {
                return
            }
            
            self.previewLayer?.frame = view.bounds
            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            view.bringSubviewToFront(self.backgroundView)
            self.backgroundView.alpha = 0
            
            view.bringSubviewToFront(self.focusAreaView)
            self.focusAreaView.alpha = 0
        }
        
        override open func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            guard !self.hasLoaded else {
                return
            }
            
            let cutoutView = self.focusAreaView.cutoutView
            let cutoutFrame = cutoutView.convert(cutoutView.bounds, to: self.view)
            
            UIView.animate(withDuration: 0.35, animations: {
                self.backgroundView.mask(cutoutFrame, invert: true, cornerRadius: self.cutoutCornerRadius)
                
                self.backgroundView.alpha = 1
                self.focusAreaView.alpha = 1
            }) { _ in
                self.metadataOutput.rectOfInterest = self.previewLayer?.metadataOutputRectConverted(fromLayerRect: cutoutFrame) ?? CGRect(x: 0, y: 0, width: 1, height: 1)
            }
            
            self.hasLoaded = true
        }
        
        override open func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            // navigationController?.navigationBar.barTintColor = startingBarTintColor
            // navigationController?.navigationBar.tintColor = startingTintColor
            // navigationController?.navigationBar.isTranslucent = false
        }
        
        open override func viewDidDisappear(_ animated: Bool) {
            self.curtain.alpha = 1
            self.previewLayer?.session = nil
            
            stopCapturing()
            
            super.viewDidDisappear(animated)
        }
        
        // MARK: Methods - Utilities
        
        public func stopCapturing() {
            sessionQueue.async {
                if self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }
        
        public func startCapturing() {
            sessionQueue.async {
                self.previewLayer?.session = self.session
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
        
        public func evolve(withText text: String) {
            if isEvolving { return }
            isEvolving = true
            
            self.focusAreaView.helpLabel.text = text
            
            let cutoutFrame = self.focusAreaView.cutoutView.convert(self.focusAreaView.cutoutView.bounds, to: self.view)
            UIView.animateWithDisplayLink(duration: 0.2, animationHandler: { [weak self] percent in
                guard let strongSelf = self else { return }
                let newWidth = cutoutFrame.width * (1 - percent)
                let newHeight = cutoutFrame.height * (1 - percent)
                let xChange = (cutoutFrame.width - newWidth)/2
                let yChange = (cutoutFrame.height - newHeight)/2
                let newFrame = CGRect(x: cutoutFrame.minX + xChange, y: cutoutFrame.minY + yChange, width: newWidth, height: newHeight)
                strongSelf.backgroundView.mask(newFrame, invert: true, cornerRadius: strongSelf.cutoutCornerRadius * (1 - percent))
            }, completionHandler: nil)
        }
    }
    
    // MARK: - Classes
    
    @available(iOS 9.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public protocol BHCameraScanControllerDelegate: AnyObject {
        func didCapture(metadataObjects: [AVMetadataObject], from controller: BHCameraScanController)
    }
    
    // MARK: - Extensions
    
    @available(iOS 9.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    extension BHCameraScanController: AVCaptureMetadataOutputObjectsDelegate {
        public func metadataOutput(_ output: AVCaptureMetadataOutput,
                                   didOutput metadataObjects: [AVMetadataObject],
                                   from connection: AVCaptureConnection) {
            guard self.session.isRunning else {
                return
            }
            
            self.delegate?.didCapture(metadataObjects: metadataObjects, from: self)
        }
    }
    
#endif
