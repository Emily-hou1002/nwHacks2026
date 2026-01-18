import UIKit

class ResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Data Variables
    var scanResult: ScanResult?
    var scanData: ScanData?

    // MARK: - UI Components
    private let scoreLabel = UILabel()
    private let scoreCircle = UIView()
    private let tableView = UITableView()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Feng Shui Report"
        navigationItem.hidesBackButton = true
        
        setupUI()
        populateData()
    }
    
    private func setupUI() {
        // 1. Score Circle (Top)
        scoreCircle.backgroundColor = .systemGreen
        scoreCircle.layer.cornerRadius = 60
        scoreCircle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreCircle)
        
        // 2. Score Label
        scoreLabel.text = "0"
        scoreLabel.font = .systemFont(ofSize: 48, weight: .bold)
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreCircle.addSubview(scoreLabel)
        
        // 3. Table View for Suggestions
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // 4. Done Button
        doneButton.setTitle("Done", for: .normal)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 10
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        view.addSubview(doneButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            scoreCircle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreCircle.widthAnchor.constraint(equalToConstant: 120),
            scoreCircle.heightAnchor.constraint(equalToConstant: 120),
            
            scoreLabel.centerXAnchor.constraint(equalTo: scoreCircle.centerXAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: scoreCircle.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: scoreCircle.bottomAnchor, constant: 30),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func populateData() {
        guard let result = scanResult else { return }
        
        // Set Score
        scoreLabel.text = "\(result.feng_shui_score)"
        
        // Color code based on score
        if result.feng_shui_score >= 80 {
            scoreCircle.backgroundColor = .systemGreen
        } else if result.feng_shui_score >= 50 {
            scoreCircle.backgroundColor = .systemOrange
        } else {
            scoreCircle.backgroundColor = .systemRed
        }
        
        tableView.reloadData()
    }

    @objc func didTapDone() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Section 0: Analysis, Section 1: Suggestions
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Zone Analysis" : "Suggestions"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return scanResult?.bagua_analysis.count ?? 0 }
        return scanResult?.suggestions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        if indexPath.section == 0 {
            // Zone Analysis
            if let zone = scanResult?.bagua_analysis[indexPath.row] {
                cell.textLabel?.text = zone.zone.capitalized
                cell.detailTextLabel?.text = "Score: \(zone.score) - \(zone.notes)"
                cell.imageView?.image = UIImage(systemName: "chart.bar.fill")
            }
        } else {
            // Suggestions
            if let suggestion = scanResult?.suggestions[indexPath.row] {
                cell.textLabel?.text = suggestion.title
                cell.detailTextLabel?.text = suggestion.description
                cell.detailTextLabel?.numberOfLines = 0 // Allow multiline
                
                // Icon based on severity
                let iconName = suggestion.severity == "high" ? "exclamationmark.triangle.fill" : "info.circle"
                cell.imageView?.image = UIImage(systemName: iconName)
                cell.imageView?.tintColor = suggestion.severity == "high" ? .systemRed : .systemBlue
            }
        }
        return cell
    }
}
