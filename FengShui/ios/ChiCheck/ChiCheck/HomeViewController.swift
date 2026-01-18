import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "ChiCheck"
        
        // Create "Start Scan" Button
        let startButton = UIButton(type: .system)
        startButton.setTitle("Start New Scan", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        
        // Layout
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add Action
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
    }
    
    @objc func didTapStart() {
        // This navigates to your existing scanner ViewController
        let scannerVC = ViewController()
        navigationController?.pushViewController(scannerVC, animated: true)
    }
}
