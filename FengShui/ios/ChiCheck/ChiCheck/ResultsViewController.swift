import UIKit

class ResultsViewController: UIViewController {

    // MARK: - 1. Receive Data
    // This variable holds the analysis passed from the Scanner
    var analysisText: String?
    var scanData: ScanData? // Optional: Keep the original user inputs if you need to display them

    // MARK: - UI Components
    private let resultsLabel = UILabel()
    private let descriptionTextView = UITextView()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Analysis"
        
        // Hide the "Back" button so the user has to click "Done" (prevents going back to AR view)
        navigationItem.hidesBackButton = true
        
        setupUI()
        displayResults()
    }
    
    private func setupUI() {
        // 1. Title Label
        resultsLabel.font = .systemFont(ofSize: 28, weight: .bold)
        resultsLabel.textAlignment = .center
        resultsLabel.text = "Feng Shui Report"
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Scrollable Description Text
        descriptionTextView.font = .systemFont(ofSize: 18)
        descriptionTextView.isEditable = false
        descriptionTextView.backgroundColor = .secondarySystemBackground
        descriptionTextView.layer.cornerRadius = 10
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Done Button
        doneButton.setTitle("Done", for: .normal)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 10
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        
        view.addSubview(resultsLabel)
        view.addSubview(descriptionTextView)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            // Label at top
            resultsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            resultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Text View in middle
            descriptionTextView.topAnchor.constraint(equalTo: resultsLabel.bottomAnchor, constant: 30),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -30),
            
            // Button at bottom
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func displayResults() {
        // Show the data if we have it, otherwise show a default message
        if let text = analysisText {
            descriptionTextView.text = text
        } else {
            descriptionTextView.text = "No analysis data found."
        }
    }

    @objc func didTapDone() {
        // Pop all the way back to the very first screen (Home)
        navigationController?.popToRootViewController(animated: true)
    }
}
