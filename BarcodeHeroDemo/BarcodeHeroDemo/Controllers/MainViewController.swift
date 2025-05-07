// Copyright © 2020 SpotHero, Inc. All rights reserved.

import BarcodeHeroUI
import UIKit
import AVKit

class MainViewController: UITableViewController, BHCameraScanControllerDelegate {
    private var onlyOnce = true
    func didCaptureBarcodes(metadataObjects: [AVMetadataObject], from controller: BHCameraScanController) {
        guard onlyOnce else { return }
        onlyOnce = false
        controller.evolve(withMode: .processing(text: "Barcode found!\nProcessing..."))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            controller.evolve(withMode: .capture)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                controller.capturePhoto()
            }
        }
    }
    func didCaptureImage(image: UIImage?, from controller: BHCameraScanController) {
        print("Image size: \(image?.size.debugDescription ?? "(none)")")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            controller.evolve(withMode: .scan)
            self?.onlyOnce = true
        }
    }
    
    // MARK: - Methods
    
    private var controller: BHCameraScanController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            switch indexPath.row {
            case 0:
                if controller == nil {
                    controller = BHCameraScanController(helpTextColor: UIColor(red: 251/255, green: 244/255, blue: 228/255, alpha: 1), cutoutCornerRadius: 10)
                }
                controller!.delegate = self
                let navController = UINavigationController(rootViewController: controller!)
                present(navController, animated: true, completion: nil)
                //show(controller, sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
}
