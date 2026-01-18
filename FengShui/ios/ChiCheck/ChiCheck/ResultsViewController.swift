import UIKit

class ResultsViewController: UIViewController {

    // MARK: - Receive Data
    var scanResult: ScanResult?
    var usdzURL: URL? // passed from ProcessingViewController
    var fileId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Immediately transition to the new Bagua UI
        showBaguaResults()
    }
    
    private func showBaguaResults() {
        let baguaVC = BaguaResultsViewController()
        baguaVC.scanResult = scanResult
        baguaVC.usdzURL = usdzURL // Pass the 3D model URL
        baguaVC.fileId = self.fileId //
        
        // Replace the navigation stack
        if let navigationController = navigationController {
            var viewControllers = navigationController.viewControllers
            if let index = viewControllers.firstIndex(of: self) {
                viewControllers.remove(at: index)
                viewControllers.insert(baguaVC, at: index)
                navigationController.setViewControllers(viewControllers, animated: false)
            }
        }
    }
}
