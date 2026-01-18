import UIKit

class HarmonicSuggestionsViewController: UIViewController {

    // MARK: - Data Properties
    var scanResult: ScanResult?
    var fileId: String? // Passed from previous screen
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header & Tabs
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let tabContainer = UIView()
    private let suggestion1Button = UIButton(type: .system)
    private let suggestion2Button = UIButton(type: .system)
    private let suggestion3Button = UIButton(type: .system)
    
    // Content Card
    private let suggestionContentView = UIView()
    private let suggestionTitleLabel = UILabel()
    private let benefitsSectionLabel = UILabel()
    private let benefitsTextView = UITextView()
    
    // MARK: - THE LAZY LOAD COMPONENTS
    private let visualizeButton = UIButton(type: .system)
    private let loadingSpinner = UIActivityIndicatorView(style: .medium)
    private let downloadProgressView = UIProgressView(progressViewStyle: .bar) // Optional polish
    
    private let doneButton = UIButton(type: .system)
    
    // State
    private var currentSuggestion: Int = 0
    
    // Colors
    private let goldColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
    private let darkGray = UIColor(white: 0.15, alpha: 1.0)
    private let mediumGray = UIColor(white: 0.25, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Harmonic Suggestions"
        navigationItem.hidesBackButton = true
        
        setupUI()
        updateContentForSuggestion(index: 0)
    }
    
    // MARK: - NETWORK REQUEST (On-Demand)
    @objc private func didTapVisualize() {
        guard let fileId = fileId else {
            print("❌ No File ID available to fetch model")
            return
        }
        
        // 1. Prepare UI (Show loading state)
        visualizeButton.setTitle(" Downloading...", for: .normal)
        visualizeButton.isEnabled = false
        loadingSpinner.startAnimating()
        downloadProgressView.isHidden = false
        downloadProgressView.progress = 0.1
        
        // 2. Construct URL for the NEW Optimized Model
        // This is the specific query you asked for
        let urlString = "https://runnier-shaniqua-yeasty.ngrok-free.dev/get-optimized-model/\(fileId)"
        guard let url = URL(string: urlString) else { return }
        
        print("🚀 [Lazy Load] Fetching optimized model from: \(url)")
        
        // 3. Create Download Task
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            // Handle Error
            if let error = error {
                print("❌ Download Error: \(error)")
                DispatchQueue.main.async { self.resetVisualizeButton(error: true) }
                return
            }
            
            // Handle Success
            guard let localURL = localURL else { return }
            
            do {
                // 4. Move file from Temp -> Documents
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                // We name it specifically so we know it's the NEW one
                let destinationURL = documentsURL.appendingPathComponent("Optimized_\(fileId).usdz")
                
                // Cleanup old file if exists
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                try fileManager.moveItem(at: localURL, to: destinationURL)
                print("✅ New Model Saved: \(destinationURL.path)")
                
                // 5. Open 3D Viewer with the NEW URL
                DispatchQueue.main.async {
                    self.resetVisualizeButton(error: false)
                    
                    let threeDVC = ThreeDResultsViewController()
                    threeDVC.usdzURL = destinationURL // <--- Passing the NEW file
                    threeDVC.modalPresentationStyle = .fullScreen
                    self.present(threeDVC, animated: true, completion: nil)
                }
                
            } catch {
                print("❌ File Save Error: \(error)")
                DispatchQueue.main.async { self.resetVisualizeButton(error: true) }
            }
        }
        
        // Monitor progress (Optional but nice)
        // task.delegate = self // requires NSObject inheritance, skipping for simplicity
        
        task.resume()
    }
    
    private func resetVisualizeButton(error: Bool) {
        loadingSpinner.stopAnimating()
        downloadProgressView.isHidden = true
        visualizeButton.isEnabled = true
        
        if error {
            visualizeButton.setTitle("Error - Try Again", for: .normal)
            visualizeButton.backgroundColor = .red.withAlphaComponent(0.5)
        } else {
            visualizeButton.setTitle("Visualize This Change", for: .normal)
            visualizeButton.backgroundColor = goldColor
        }
    }
    
    // MARK: - UI Setup (Abbreviated for clarity)
    private func setupUI() {
        setupScrollView()
        setupHeader()
        setupTabButtons()
        setupSuggestionContent()
        setupDoneButton()
        
        let count = scanResult?.suggestions.count ?? 0
        suggestion2Button.isEnabled = count >= 2
        suggestion3Button.isEnabled = count >= 3
        suggestion2Button.alpha = count >= 2 ? 1.0 : 0.3
        suggestion3Button.alpha = count >= 3 ? 1.0 : 0.3
    }
    
    private func setupSuggestionContent() {
        suggestionContentView.translatesAutoresizingMaskIntoConstraints = false
        suggestionContentView.backgroundColor = darkGray
        suggestionContentView.layer.cornerRadius = 20
        suggestionContentView.layer.borderWidth = 1
        suggestionContentView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        contentView.addSubview(suggestionContentView)
        
        suggestionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        suggestionTitleLabel.font = .systemFont(ofSize: 20, weight: .light)
        suggestionTitleLabel.textColor = .white
        suggestionTitleLabel.numberOfLines = 0
        suggestionContentView.addSubview(suggestionTitleLabel)
        
        benefitsSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        benefitsSectionLabel.text = "why this helps"
        benefitsSectionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        benefitsSectionLabel.textColor = goldColor
        suggestionContentView.addSubview(benefitsSectionLabel)
        
        benefitsTextView.translatesAutoresizingMaskIntoConstraints = false
        benefitsTextView.font = .systemFont(ofSize: 15, weight: .regular)
        benefitsTextView.textColor = UIColor.white.withAlphaComponent(0.9)
        benefitsTextView.backgroundColor = mediumGray
        benefitsTextView.layer.cornerRadius = 12
        benefitsTextView.isEditable = false
        benefitsTextView.isScrollEnabled = false
        benefitsTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        suggestionContentView.addSubview(benefitsTextView)
        
        // --- VISUALIZE BUTTON SETUP ---
        visualizeButton.translatesAutoresizingMaskIntoConstraints = false
        visualizeButton.setTitle("Visualize This Change", for: .normal)
        visualizeButton.setImage(UIImage(systemName: "wand.and.stars"), for: .normal)
        visualizeButton.tintColor = .black
        visualizeButton.backgroundColor = goldColor
        visualizeButton.setTitleColor(.black, for: .normal)
        visualizeButton.layer.cornerRadius = 12
        visualizeButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        
        // Button Config for Icon Spacing
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = goldColor
        config.baseForegroundColor = .black
        config.imagePadding = 10
        visualizeButton.configuration = config
        
        visualizeButton.addTarget(self, action: #selector(didTapVisualize), for: .touchUpInside)
        suggestionContentView.addSubview(visualizeButton)
        
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.color = .black
        suggestionContentView.addSubview(loadingSpinner)
        
        downloadProgressView.translatesAutoresizingMaskIntoConstraints = false
        downloadProgressView.progressTintColor = .black
        downloadProgressView.trackTintColor = .clear
        downloadProgressView.isHidden = true
        suggestionContentView.addSubview(downloadProgressView)
        
        NSLayoutConstraint.activate([
            suggestionContentView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            suggestionContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            suggestionContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            suggestionTitleLabel.topAnchor.constraint(equalTo: suggestionContentView.topAnchor, constant: 25),
            suggestionTitleLabel.leadingAnchor.constraint(equalTo: suggestionContentView.leadingAnchor, constant: 20),
            suggestionTitleLabel.trailingAnchor.constraint(equalTo: suggestionContentView.trailingAnchor, constant: -20),
            
            benefitsSectionLabel.topAnchor.constraint(equalTo: suggestionTitleLabel.bottomAnchor, constant: 25),
            benefitsSectionLabel.leadingAnchor.constraint(equalTo: suggestionContentView.leadingAnchor, constant: 20),
            benefitsSectionLabel.trailingAnchor.constraint(equalTo: suggestionContentView.trailingAnchor, constant: -20),
            
            benefitsTextView.topAnchor.constraint(equalTo: benefitsSectionLabel.bottomAnchor, constant: 12),
            benefitsTextView.leadingAnchor.constraint(equalTo: suggestionContentView.leadingAnchor, constant: 20),
            benefitsTextView.trailingAnchor.constraint(equalTo: suggestionContentView.trailingAnchor, constant: -20),
            
            // Visualize Button
            visualizeButton.topAnchor.constraint(equalTo: benefitsTextView.bottomAnchor, constant: 25),
            visualizeButton.leadingAnchor.constraint(equalTo: suggestionContentView.leadingAnchor, constant: 20),
            visualizeButton.trailingAnchor.constraint(equalTo: suggestionContentView.trailingAnchor, constant: -20),
            visualizeButton.heightAnchor.constraint(equalToConstant: 50),
            visualizeButton.bottomAnchor.constraint(equalTo: suggestionContentView.bottomAnchor, constant: -25),
            
            loadingSpinner.centerXAnchor.constraint(equalTo: visualizeButton.centerXAnchor, constant: -80), // Offset slightly
            loadingSpinner.centerYAnchor.constraint(equalTo: visualizeButton.centerYAnchor),
            
            downloadProgressView.bottomAnchor.constraint(equalTo: visualizeButton.bottomAnchor),
            downloadProgressView.leadingAnchor.constraint(equalTo: visualizeButton.leadingAnchor),
            downloadProgressView.trailingAnchor.constraint(equalTo: visualizeButton.trailingAnchor),
            downloadProgressView.heightAnchor.constraint(equalToConstant: 3)
        ])
    }
    
    // ... Rest of the helper methods (setupScrollView, setupHeader, tab logic) same as before ...
    
    // MARK: - Helper Methods Copied for Completeness
    private func getSuggestion(at index: Int) -> Suggestion? {
        guard let suggestions = scanResult?.suggestions, index < suggestions.count else { return nil }
        return suggestions[index]
    }
    
    private func updateContentForSuggestion(index: Int) {
        currentSuggestion = index
        let buttons = [suggestion1Button, suggestion2Button, suggestion3Button]
        for (i, btn) in buttons.enumerated() {
            var config = btn.configuration
            config?.baseForegroundColor = (i == index) ? goldColor : UIColor.white.withAlphaComponent(0.7)
            btn.configuration = config
            btn.backgroundColor = (i == index) ? mediumGray : .clear
        }
        
        if let suggestion = getSuggestion(at: index) {
            suggestionTitleLabel.text = suggestion.title.lowercased()
            benefitsTextView.text = suggestion.description.lowercased()
        } else {
            suggestionTitleLabel.text = "no suggestion available"
            benefitsTextView.text = "try scanning again."
        }
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = darkGray
        contentView.addSubview(headerView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "leaf.circle.fill"); logoImageView.tintColor = goldColor
        headerView.addSubview(logoImageView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false; titleLabel.text = "harmonic suggestions"; titleLabel.font = .systemFont(ofSize: 28, weight: .light); titleLabel.textColor = .white; titleLabel.textAlignment = .center; titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false; subtitleLabel.text = "enhance your space's energy"; subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular); subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7); subtitleLabel.textAlignment = .center
        headerView.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor), headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), headerView.heightAnchor.constraint(equalToConstant: 200),
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40), logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor), logoImageView.widthAnchor.constraint(equalToConstant: 40), logoImageView.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 15), titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20), titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8), subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20), subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTabButtons() {
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        tabContainer.backgroundColor = darkGray
        tabContainer.layer.cornerRadius = 25
        tabContainer.layer.borderWidth = 1
        tabContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        contentView.addSubview(tabContainer)
        configureTabButton(suggestion1Button, number: "1"); configureTabButton(suggestion2Button, number: "2"); configureTabButton(suggestion3Button, number: "3")
        suggestion1Button.addTarget(self, action: #selector(didTapSuggestion1), for: .touchUpInside); suggestion2Button.addTarget(self, action: #selector(didTapSuggestion2), for: .touchUpInside); suggestion3Button.addTarget(self, action: #selector(didTapSuggestion3), for: .touchUpInside)
        tabContainer.addSubview(suggestion1Button); tabContainer.addSubview(suggestion2Button); tabContainer.addSubview(suggestion3Button)
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20), tabContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), tabContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20), tabContainer.heightAnchor.constraint(equalToConstant: 50),
            suggestion1Button.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 10), suggestion1Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor), suggestion1Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            suggestion2Button.centerXAnchor.constraint(equalTo: tabContainer.centerXAnchor), suggestion2Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor), suggestion2Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            suggestion3Button.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -10), suggestion3Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor), suggestion3Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28)
        ])
    }
    private func configureTabButton(_ button: UIButton, number: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = "tip \(number)"
        button.configuration = config
        button.layer.cornerRadius = 20
    }
    private func setupDoneButton() {
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("done", for: .normal)
        doneButton.backgroundColor = .white
        doneButton.setTitleColor(.black, for: .normal)
        doneButton.layer.cornerRadius = 28
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40), doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40), doneButton.heightAnchor.constraint(equalToConstant: 56),
            contentView.bottomAnchor.constraint(equalTo: suggestionContentView.bottomAnchor, constant: 100)
        ])
    }
    @objc private func didTapSuggestion1() { updateContentForSuggestion(index: 0) }
    @objc private func didTapSuggestion2() { updateContentForSuggestion(index: 1) }
    @objc private func didTapSuggestion3() { updateContentForSuggestion(index: 2) }
    @objc func didTapDone() { navigationController?.popToRootViewController(animated: true) }
}
