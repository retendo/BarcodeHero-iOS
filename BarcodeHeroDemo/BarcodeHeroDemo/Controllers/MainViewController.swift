// Copyright © 2020 SpotHero, Inc. All rights reserved.

import BarcodeHeroUI
import UIKit

class MainViewController: UITableViewController {
    // MARK: - Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            switch indexPath.row {
            case 0:
                let controller = BHCameraScanController(helpTextColor: UIColor(red: 251/255, green: 244/255, blue: 228/255, alpha: 1), cutoutCornerRadius: 10)
                let navController = UINavigationController(rootViewController: controller)
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
