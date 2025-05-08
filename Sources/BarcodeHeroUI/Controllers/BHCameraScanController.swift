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
            let backgroundView = UIView(frame: .zero)
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(backgroundView)
            
            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                backgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor),
                backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])
            
            return backgroundView
        }()
        
        private lazy var focusAreaView: BHFocusAreaView = {
            let focusAreaView = BHFocusAreaView()
            focusAreaView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(focusAreaView)
            
            NSLayoutConstraint.activate([
                focusAreaView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                focusAreaView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -48),
                focusAreaView.widthAnchor.constraint(equalTo: self.view.widthAnchor)
            ])
            
            return focusAreaView
        }()
        
        private let session = AVCaptureSession()
        
        private let sessionQueue = DispatchQueue(label: "barcodehero.capturesession")
        
//    private var dismissOnScan: Bool = false
        private var hasLoaded: Bool = false
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private lazy var curtain: UIView = {
            let curtain = UIView(frame: .zero)
            curtain.backgroundColor = UIColor.black
            curtain.translatesAutoresizingMaskIntoConstraints = false;
            
            self.view.addSubview(curtain)
            
            NSLayoutConstraint.activate([
                curtain.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                curtain.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                curtain.topAnchor.constraint(equalTo: self.view.topAnchor),
                curtain.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])
            
            return curtain
        }()
        
        // Photo capture
        private lazy var photoOutput = AVCapturePhotoOutput()
        
//    private var startingBarTintColor: UIColor?
//    private var startingTintColor: UIColor?
        
        private var helpText: String = "Focus the barcode inside\nthe rectangle above"
        private var helpTextColor: UIColor = .white
        private var helpTextFont: UIFont = .systemFont(ofSize: 20, weight: .regular)
        private var cutoutCornerRadius: CGFloat = 4.0
        private var jpegQuality: CGFloat = 0.95
        
        private let metadataOutput = AVCaptureMetadataOutput()
        
        private var isEvolving = false
        private var currentMode: BHScanMode = .scan
        
        public weak var delegate: BHCameraScanControllerDelegate?
        public weak var imageCaptureDelegate: BHCameraScanControllerImageCaptureDelegate?
        
        // MARK: Methods - Initializers
        
        public init(helpText: String? = nil,
                    helpTextColor: UIColor? = nil,
                    helpTextFont: UIFont? = nil,
                    cutoutCornerRadius: CGFloat? = nil,
                    jpegQuality: CGFloat? = nil) {
            if let helpText = helpText { self.helpText = helpText }
            if let helpTextColor = helpTextColor { self.helpTextColor = helpTextColor }
            if let helpTextFont = helpTextFont { self.helpTextFont = helpTextFont }
            if let cutoutCornerRadius = cutoutCornerRadius { self.cutoutCornerRadius = cutoutCornerRadius }
            if let jpegQuality = jpegQuality { self.jpegQuality = jpegQuality }
            
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
                
                // Add the photo output to the session
                if self.session.canAddOutput(photoOutput) {
                    self.session.addOutput(photoOutput)
                }
            }
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce]
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            
            view.backgroundColor = .black
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
            
            self.previewLayer?.frame = view.bounds
            
            guard !self.hasLoaded else {
                return
            }
            
            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            view.bringSubviewToFront(self.backgroundView)
            self.backgroundView.alpha = 0
            
            view.bringSubviewToFront(self.focusAreaView)
            self.focusAreaView.alpha = 0
        }
        
        override open func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            self.hasLoaded = true
            
            evolve(withMode: .scan)
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
        
        public enum FlashStatus {
            case off, on, unavailable
        }
        public func getFlashStatus() -> FlashStatus {
            guard let avDevice = AVCaptureDevice.default(for: .video), avDevice.hasTorch, avDevice.isTorchAvailable else { return .unavailable }
            return avDevice.isTorchActive ? .on : .off
        }
        public func toggleFlashStatus() -> FlashStatus {
            guard let avDevice = AVCaptureDevice.default(for: .video), avDevice.hasTorch, avDevice.isTorchAvailable, (try? avDevice.lockForConfiguration()) != nil else {
                AVCaptureDevice.default(for: .video)?.unlockForConfiguration()
                return .unavailable
            }
            defer { avDevice.unlockForConfiguration() }

            if avDevice.isTorchActive {
                avDevice.torchMode = AVCaptureDevice.TorchMode.off
                return .off
            } else {
                avDevice.torchMode = AVCaptureDevice.TorchMode.on
                return .on
            }
        }
        
        public func evolve(withMode mode: BHScanMode) {
            if !hasLoaded || isEvolving { return }
            isEvolving = true
            
            switch mode {
            case .scan:
                self.focusAreaView.helpLabel.text = helpText
            case .capture:
                self.focusAreaView.helpLabel.text = ""
            case .processing(let text):
                self.focusAreaView.helpLabel.text = text
            }
            
            func getTargetFrame(mode: BHScanMode) -> CGRect {
                let scanCutoutFrame = self.focusAreaView.cutoutView.convert(self.focusAreaView.cutoutView.bounds, to: self.view).offsetBy(dx: 0, dy: -24)
                switch mode {
                case .scan:
                    return scanCutoutFrame
                case .capture:
                    return view.bounds
                case .processing:
                    return CGRect(
                        x: scanCutoutFrame.midX,
                        y: scanCutoutFrame.midY,
                        width: 0,
                        height: 0
                    )
                }
            }
            
            func getTargetCornerRadius(mode: BHScanMode) -> CGFloat {
                switch mode {
                case .scan:
                    return cutoutCornerRadius
                case .processing, .capture:
                    return 0
                }
            }
            
            let startFrame = getTargetFrame(mode: currentMode)
            let targetFrame = getTargetFrame(mode: mode)
            
            let startCornerRadius = getTargetCornerRadius(mode: currentMode)
            let targetCornerRadius = getTargetCornerRadius(mode: mode)
            
            UIView.animateWithDisplayLink(duration: 0.2, animationHandler: { [weak self] percent in
                guard let self else { return }
                
                // Calculate new frame by interpolating between start and target frames
                let newWidth = startFrame.width + (targetFrame.width - startFrame.width) * percent
                let newHeight = startFrame.height + (targetFrame.height - startFrame.height) * percent
                
                // Calculate new origin to keep the frame centered
                let newX = startFrame.minX + (targetFrame.minX - startFrame.minX) * percent
                let newY = startFrame.minY + (targetFrame.minY - startFrame.minY) * percent
                
                let newFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
                
                // Calculate new corner radius by linear interpolation
                let newCornerRadius = startCornerRadius + (targetCornerRadius - startCornerRadius) * percent
                
                // Apply the mask with the new frame and corner radius
                backgroundView.mask(newFrame, invert: true, cornerRadius: newCornerRadius)
                
                backgroundView.alpha = 1
                focusAreaView.alpha = 1
                
            }, completionHandler: { [weak self] in
                guard let self else { return }
                // Update the metadataOutput rectOfInterest if in scan mode
                // Enable/disable barcode detection based on mode
                if case .scan = mode {
                    metadataOutput.rectOfInterest = previewLayer?.metadataOutputRectConverted(fromLayerRect: targetFrame) ?? CGRect(x: 0, y: 0, width: 1, height: 1)
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                } else {
                    metadataOutput.setMetadataObjectsDelegate(nil, queue: nil)
                }
                
                currentMode = mode
                isEvolving = false
            })
        }
        
        // Add a method to capture a still photo
        public func capturePhoto() {
            guard session.isRunning else {
                self.imageCaptureDelegate?.didCaptureImage(image: nil, from: self)
                return
            }
            
            sessionQueue.async {
                let photoSettings = AVCapturePhotoSettings()
                self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
    // MARK: - Classes

    public enum BHScanMode {
        case scan
        case capture
        case processing(text: String)
    }
    
    @available(iOS 9.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @objc public protocol BHCameraScanControllerDelegate: AnyObject {
        func didCaptureBarcodes(metadataObjects: [AVMetadataObject], from controller: BHCameraScanController)
    }
    @available(iOS 9.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @objc public protocol BHCameraScanControllerImageCaptureDelegate: AnyObject {
        func didCaptureImage(image: UIImage?, from controller: BHCameraScanController)
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
            
            self.delegate?.didCaptureBarcodes(metadataObjects: metadataObjects, from: self)
        }
    }

    @available(iOS 11.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    extension BHCameraScanController: AVCapturePhotoCaptureDelegate {
        public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                DispatchQueue.main.async {
                    self.imageCaptureDelegate?.didCaptureImage(image: nil, from: self)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.imageCaptureDelegate?.didCaptureImage(image: image, from: self)
            }
        }
        
        // For iOS 10 compatibility
        public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
            guard let photoSampleBuffer = photoSampleBuffer,
                  let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
                  let image = UIImage(data: imageData) else {
                DispatchQueue.main.async {
                    self.imageCaptureDelegate?.didCaptureImage(image: nil, from: self)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.imageCaptureDelegate?.didCaptureImage(image: image, from: self)
            }
        }
    }
    
#endif
