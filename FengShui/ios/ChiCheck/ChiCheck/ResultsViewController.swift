import UIKit

// MARK: - Model Definition
// This must match the JSON returned by your FastAPI backend.


class ResultsViewController: UIViewController {
    
    // MARK: - Data Variables
    var scanResult: ScanResult?
    var scanData: ScanData?
    var usdzURL: URL? // Received from ProcessingViewController
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView() // Added scroll view for long text
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let bodyLabel = UILabel()
    private let dev3DButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Analysis Results"
        navigationItem.hidesBackButton = true
        
        setupUI()
        displayResults()
    }
    
    func setupUI() {
        // 0. Scroll View Setup (Essential for variable length text)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100), // Leave room for button
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 1. Title Label
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.text = "Feng Shui Analysis"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // 2. Score Label (Big Number)
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 48, weight: .heavy)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0) // Gold
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreLabel)
        
        // 3. Body/Analysis
        bodyLabel.font = .systemFont(ofSize: 16)
        bodyLabel.numberOfLines = 0 // Allow infinite lines
        bodyLabel.textAlignment = .left
        bodyLabel.textColor = .lightGray
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)
        
        // 4. The DEV 3D BUTTON (Fixed at bottom, outside scroll view)
        dev3DButton.setTitle("View 3D Energy Map", for: .normal)
        dev3DButton.setImage(UIImage(systemName: "cube.transparent"), for: .normal)
        dev3DButton.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        dev3DButton.tintColor = .white
        dev3DButton.layer.cornerRadius = 12
        dev3DButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        dev3DButton.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 10
        dev3DButton.configuration = config
        dev3DButton.addTarget(self, action: #selector(didTapDev3D), for: .touchUpInside)
        
        view.addSubview(dev3DButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Score
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Body
            bodyLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 30),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40), // Push content size
            
            // Dev Button (Fixed to View Bottom)
            dev3DButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            dev3DButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dev3DButton.widthAnchor.constraint(equalToConstant: 240),
            dev3DButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func displayResults() {
            guard let result = scanResult else {
                scoreLabel.text = "--"
                bodyLabel.text = "Error: No analysis data received."
                return
            }
            
            // 1. Set Score (Matches 'feng_shui_score')
            scoreLabel.text = "\(result.feng_shui_score)"
            
            // 2. Build Text
            var fullText = ""
            
            // --- BAGUA ZONES ---
            if !result.bagua_analysis.isEmpty {
                fullText += "BAGUA ANALYSIS\n"
                for zone in result.bagua_analysis {
                    // Formatting: "Wealth (85): Good energy flow..."
                    fullText += "• \(zone.zone.capitalized) (\(zone.score)): \(zone.notes)\n\n"
                }
            }
            
            // --- SUGGESTIONS ---
            if !result.suggestions.isEmpty {
                fullText += "SUGGESTIONS\n"
                for (index, suggestion) in result.suggestions.enumerated() {
                    // Formatting: "1. Move Desk (High Priority)\n   Avoid facing the wall..."
                    let priority = suggestion.severity.capitalized
                    fullText += "\(index + 1). \(suggestion.title) (\(priority))\n"
                    fullText += "   \(suggestion.description)\n\n"
                }
            }
            
            // 3. Apply Formatting
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.paragraphSpacing = 10
            
            let attrString = NSMutableAttributedString(string: fullText)
            attrString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: attrString.length)
            )
            
            // Make headers bold (Optional polish)
            let boldFont = UIFont.boldSystemFont(ofSize: 18)
            let headers = ["BAGUA ANALYSIS", "SUGGESTIONS"]
            
            for header in headers {
                if let range = fullText.range(of: header) {
                    let nsRange = NSRange(range, in: fullText)
                    attrString.addAttribute(.font, value: boldFont, range: nsRange)
                    attrString.addAttribute(.foregroundColor, value: UIColor.white, range: nsRange)
                }
            }
            
            bodyLabel.attributedText = attrString
        }
    
    // MARK: - Actions
    
    @objc func didTapDev3D() {
        let threeDVC = ThreeDResultsViewController()
        threeDVC.usdzURL = self.usdzURL
        threeDVC.modalPresentationStyle = .fullScreen
        present(threeDVC, animated: true, completion: nil)
    }
}
