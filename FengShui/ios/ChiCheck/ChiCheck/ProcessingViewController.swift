import UIKit
import QuickLook

class ProcessingViewController: UIViewController {
    
    // Variables passed from ViewController
    var usdzURL: URL?
    var jsonURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Scan Complete"
        
        setupUI()
    }
    
    func setupUI() {
        // 1. Success Icon
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Status Label
        let label = UILabel()
        label.text = "Feng Shui Data Ready"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Export Button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export JSON & USDZ", for: .normal)
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 10
        exportButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Action
        exportButton.addTarget(self, action: #selector(shareFiles), for: .touchUpInside)
        
        view.addSubview(iconView)
        view.addSubview(label)
        view.addSubview(exportButton)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 220),
            exportButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func shareFiles() {
        // CRITICAL: Ensure we unwrap both URLs safely
        guard let modelURL = usdzURL, let dataURL = jsonURL else {
            print("Missing file URLs")
            return
        }
        
        // Pass BOTH items to the activity controller
        let items: [Any] = [modelURL, dataURL]
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // iPad Popover support (required for iPad)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
}
