// Copyright © 2020 SpotHero, Inc. All rights reserved.

import AVFoundation
import BarcodeHeroUI
import Foundation
import UIKit

class ReaderDelegationController: UIViewController {
    @IBOutlet private var dataLabel: UILabel!
    @IBOutlet private var typeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataLabel?.text = ""
        self.typeLabel?.text = ""
    }
    
    @IBAction private func onScanButtonTapped() {
        let controller = BHCameraScanController()
        controller.delegate = self
        
        show(controller, sender: nil)
    }
}

extension ReaderDelegationController: BHCameraScanControllerDelegate {
    func didCaptureBarcodes(metadataObjects: [AVMetadataObject], from controller: BHCameraScanController) {
        let firstObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        
        self.dataLabel?.text = firstObject?.stringValue
        self.typeLabel?.text = firstObject?.type.rawValue
        
        navigationController?.popToViewController(self, animated: true)
        
        controller.stopCapturing()
    }
}
