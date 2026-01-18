import UIKit

class ResultsViewController: UIViewController {

    // MARK: - Receive Data
    // This variable holds the analysis passed from the Scanner
    var analysisText: String?
    var scanData: ScanData? // Optional: Keep the original user inputs if you need to display them
    var scanResult: ScanResult? // Backend data

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Immediately show the Bagua Results screen
        showBaguaResults()
    }
    
    private func showBaguaResults() {
        let baguaVC = BaguaResultsViewController()
        baguaVC.scanResult = scanResult
        
        // Replace the navigation stack with the Bagua screen
        if let navigationController = navigationController {
            var viewControllers = navigationController.viewControllers
            // Remove this ResultsViewController and add BaguaResultsViewController
            if let index = viewControllers.firstIndex(of: self) {
                viewControllers.remove(at: index)
                viewControllers.insert(baguaVC, at: index)
                navigationController.setViewControllers(viewControllers, animated: false)
            }
        }
    }
}
