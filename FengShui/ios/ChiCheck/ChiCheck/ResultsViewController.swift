/*import UIKit

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
} */
import UIKit

class ResultsViewController: UIViewController {

    // MARK: - Data Properties
    var analysisText: String?
    var scanData: ScanData?
    var scanResult: ScanResult? // Backend data (when ready)
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Info Cards
    private let kuaNumberCard = UIView()
    private let kuaNumberLabel = UILabel()
    private let kuaValueLabel = UILabel()
    
    private let themeCard = UIView()
    private let themeLabel = UILabel()
    private let themeValueLabel = UILabel()
    
    private let focusCard = UIView()
    private let focusLabel = UILabel()
    private let focusValueLabel = UILabel()
    
    // Tab Buttons
    private let tabContainer = UIView()
    private let tipsButton = UIButton(type: .system)
    private let elementsButton = UIButton(type: .system)
    private let mapButton = UIButton(type: .system)
    
    // Content Views
    private let tipsContentView = UIView()
    private let elementsContentView = UIView()
    private let mapContentView = UIView()
    
    // Done Button
    private let doneButton = UIButton(type: .system)
    
    // State
    private var currentTab: Tab = .tips
    
    enum Tab {
        case tips, elements, map
    }
    
    // MARK: - Color Palette
    private let babyBlue = UIColor(hex: "8FFBFF") ?? UIColor.systemBlue
    private let babyYellow = UIColor(hex: "FFEA8F") ?? UIColor.systemYellow
    private let mint = UIColor(hex: "8FFF9A") ?? UIColor.systemGreen
    private let gradientStartColor = UIColor(hex: "0066FF") ?? UIColor.systemBlue
    private let gradientEndColor = UIColor(hex: "00CC99") ?? UIColor.systemTeal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = "Analysis"
        navigationItem.hidesBackButton = true
        
        setupUI()
        loadPlaceholderData()
        showTab(.tips)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        setupScrollView()
        setupHeader()
        setupInfoCards()
        setupTabButtons()
        setupContentViews()
        setupDoneButton()
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
        contentView.addSubview(headerView)
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 280)
        headerView.layer.insertSublayer(gradientLayer, at: 0)
        headerView.layer.cornerRadius = 20
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        // Logo
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "leaf.circle.fill")
        logoImageView.tintColor = .white
        headerView.addSubview(logoImageView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Your Feng Shui Analysis"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Personalized for your bedroom"
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 280),
            
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupInfoCards() {
        // Kua Number Card
        setupCard(kuaNumberCard, backgroundColor: babyBlue.withAlphaComponent(0.3))
        kuaNumberLabel.text = "Kua Number"
        kuaNumberLabel.font = .systemFont(ofSize: 16, weight: .regular)
        kuaNumberLabel.textColor = .darkGray
        kuaNumberLabel.textAlignment = .center
        
        kuaValueLabel.text = "4"
        kuaValueLabel.font = .systemFont(ofSize: 36, weight: .bold)
        kuaValueLabel.textColor = UIColor(hex: "0066FF")
        kuaValueLabel.textAlignment = .center
        
        kuaNumberCard.addSubview(kuaNumberLabel)
        kuaNumberCard.addSubview(kuaValueLabel)
        
        // Theme Card
        setupCard(themeCard, backgroundColor: mint.withAlphaComponent(0.3))
        themeLabel.text = "Theme"
        themeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        themeLabel.textColor = .darkGray
        themeLabel.textAlignment = .center
        
        themeValueLabel.text = "Traditional"
        themeValueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        themeValueLabel.textColor = UIColor(hex: "00AA66")
        themeValueLabel.textAlignment = .center
        
        themeCard.addSubview(themeLabel)
        themeCard.addSubview(themeValueLabel)
        
        // Focus Card
        setupCard(focusCard, backgroundColor: mint.withAlphaComponent(0.2))
        focusLabel.text = "Your Focus"
        focusLabel.font = .systemFont(ofSize: 16, weight: .regular)
        focusLabel.textColor = .darkGray
        focusLabel.textAlignment = .center
        
        focusValueLabel.text = "Creativity"
        focusValueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        focusValueLabel.textColor = .darkGray
        focusValueLabel.textAlignment = .center
        
        focusCard.addSubview(focusLabel)
        focusCard.addSubview(focusValueLabel)
        
        contentView.addSubview(kuaNumberCard)
        contentView.addSubview(themeCard)
        contentView.addSubview(focusCard)
        
        kuaNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        kuaValueLabel.translatesAutoresizingMaskIntoConstraints = false
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        themeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        focusLabel.translatesAutoresizingMaskIntoConstraints = false
        focusValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Kua Number Card
            kuaNumberCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            kuaNumberCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            kuaNumberCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            kuaNumberCard.heightAnchor.constraint(equalToConstant: 100),
            
            kuaNumberLabel.topAnchor.constraint(equalTo: kuaNumberCard.topAnchor, constant: 15),
            kuaNumberLabel.centerXAnchor.constraint(equalTo: kuaNumberCard.centerXAnchor),
            
            kuaValueLabel.topAnchor.constraint(equalTo: kuaNumberLabel.bottomAnchor, constant: 5),
            kuaValueLabel.centerXAnchor.constraint(equalTo: kuaNumberCard.centerXAnchor),
            
            // Theme Card
            themeCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            themeCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            themeCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            themeCard.heightAnchor.constraint(equalToConstant: 100),
            
            themeLabel.topAnchor.constraint(equalTo: themeCard.topAnchor, constant: 15),
            themeLabel.centerXAnchor.constraint(equalTo: themeCard.centerXAnchor),
            
            themeValueLabel.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 5),
            themeValueLabel.centerXAnchor.constraint(equalTo: themeCard.centerXAnchor),
            
            // Focus Card
            focusCard.topAnchor.constraint(equalTo: kuaNumberCard.bottomAnchor, constant: 15),
            focusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            focusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            focusCard.heightAnchor.constraint(equalToConstant: 100),
            
            focusLabel.topAnchor.constraint(equalTo: focusCard.topAnchor, constant: 15),
            focusLabel.centerXAnchor.constraint(equalTo: focusCard.centerXAnchor),
            
            focusValueLabel.topAnchor.constraint(equalTo: focusLabel.bottomAnchor, constant: 5),
            focusValueLabel.centerXAnchor.constraint(equalTo: focusCard.centerXAnchor)
        ])
    }
    
    private func setupCard(_ card: UIView, backgroundColor: UIColor?) {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = backgroundColor
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    private func setupTabButtons() {
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        tabContainer.backgroundColor = UIColor.systemGray6
        tabContainer.layer.cornerRadius = 25
        contentView.addSubview(tabContainer)
        
        configureTabButton(tipsButton, title: "Tips", icon: "lightbulb")
        configureTabButton(elementsButton, title: "Elements", icon: "circle.hexagongrid")
        configureTabButton(mapButton, title: "Map", icon: "map")
        
        tipsButton.addTarget(self, action: #selector(didTapTips), for: .touchUpInside)
        elementsButton.addTarget(self, action: #selector(didTapElements), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(didTapMap), for: .touchUpInside)
        
        tabContainer.addSubview(tipsButton)
        tabContainer.addSubview(elementsButton)
        tabContainer.addSubview(mapButton)
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: focusCard.bottomAnchor, constant: 20),
            tabContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabContainer.heightAnchor.constraint(equalToConstant: 50),
            
            tipsButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 10),
            tipsButton.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            tipsButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            
            elementsButton.centerXAnchor.constraint(equalTo: tabContainer.centerXAnchor),
            elementsButton.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            elementsButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            
            mapButton.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -10),
            mapButton.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            mapButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28)
        ])
    }
    
    private func configureTabButton(_ button: UIButton, title: String, icon: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Use UIButton.Configuration (iOS 15+) instead of deprecated edge insets
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 5
        config.imagePlacement = .leading
        config.baseForegroundColor = .darkGray
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        
        button.configuration = config
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
    }
    
    private func setupContentViews() {
        // Tips Content
        tipsContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tipsContentView)
        setupTipsContent()
        
        // Elements Content
        elementsContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(elementsContentView)
        setupElementsContent()
        
        // Map Content
        mapContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mapContentView)
        setupMapContent()
        
        NSLayoutConstraint.activate([
            tipsContentView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            tipsContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tipsContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            elementsContentView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            elementsContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            elementsContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            mapContentView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            mapContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mapContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTipsContent() {
        // Placeholder tips - will be replaced with backend data
        let tips = [
            ("Place your bed in the East direction", "Based on your Kua number, East is your best direction for health and vitality.", "high"),
            ("Add wooden elements", "Incorporate plants or wooden furniture to enhance positive energy flow.", "high"),
            ("Use warm, earthy tones", "Colors like terracotta, beige, and soft greens will harmonize with your space.", "medium")
        ]
        
        var previousView: UIView = tipsContentView
        
        for (index, tip) in tips.enumerated() {
            let tipCard = createTipCard(title: tip.0, description: tip.1, severity: tip.2)
            tipsContentView.addSubview(tipCard)
            
            NSLayoutConstraint.activate([
                tipCard.topAnchor.constraint(equalTo: index == 0 ? tipsContentView.topAnchor : previousView.bottomAnchor, constant: index == 0 ? 0 : 15),
                tipCard.leadingAnchor.constraint(equalTo: tipsContentView.leadingAnchor),
                tipCard.trailingAnchor.constraint(equalTo: tipsContentView.trailingAnchor)
            ])
            
            previousView = tipCard
        }
        
        tipsContentView.bottomAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 20).isActive = true
    }
    
    private func createTipCard(title: String, description: String, severity: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Left border accent
        let accentView = UIView()
        accentView.translatesAutoresizingMaskIntoConstraints = false
        accentView.backgroundColor = UIColor(hex: "0066FF")
        accentView.layer.cornerRadius = 2
        card.addSubview(accentView)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 0
        card.addSubview(titleLabel)
        
        // Description
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .darkGray
        descLabel.numberOfLines = 0
        card.addSubview(descLabel)
        
        // Severity badge
        let badge = UIView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.layer.cornerRadius = 10
        
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.text = severity
        badgeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        
        switch severity {
        case "high":
            badge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            badgeLabel.textColor = .systemRed
        case "medium":
            badge.backgroundColor = babyYellow.withAlphaComponent(0.4)
            badgeLabel.textColor = UIColor.systemOrange
        case "low":
            badge.backgroundColor = babyBlue.withAlphaComponent(0.3)
            badgeLabel.textColor = UIColor.systemBlue
        default:
            badge.backgroundColor = .systemGray5
            badgeLabel.textColor = .darkGray
        }
        
        badge.addSubview(badgeLabel)
        card.addSubview(badge)
        
        NSLayoutConstraint.activate([
            accentView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            accentView.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            accentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15),
            accentView.widthAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: badge.leadingAnchor, constant: -10),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15),
            
            badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            badge.heightAnchor.constraint(equalToConstant: 28),
            
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 5),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 12),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -12),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -5)
        ])
        
        return card
    }
    
    private func setupElementsContent() {
        // Create elements with icons
        let elements = [
            ("Wood", "mountain.2", mint, 0.25),
            ("Fire", "flame", UIColor.systemRed.withAlphaComponent(0.2), 0.15),
            ("Earth", "mountain.2", babyYellow, 0.20),
            ("Metal", "wind", UIColor.systemGray5, 0.10),
            ("Water", "drop", babyBlue, 0.30)
        ]
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        elementsContentView.addSubview(stackView)
        
        for element in elements {
            let elementView = createElementView(name: element.0, icon: element.1, color: element.2, percentage: element.3)
            stackView.addArrangedSubview(elementView)
        }
        
        // Description label
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = "Your room has strong Wood and Water elements. Consider adding Earth elements to enhance creativity energy."
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .darkGray
        descLabel.numberOfLines = 0
        descLabel.backgroundColor = mint.withAlphaComponent(0.15)
        descLabel.layer.cornerRadius = 12
        descLabel.clipsToBounds = true
        descLabel.textAlignment = .center
        
        let padding: CGFloat = 15
        descLabel.layer.sublayerTransform = CATransform3DMakeTranslation(padding, padding, 0)
        
        let paddingView = UIView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        paddingView.addSubview(descLabel)
        elementsContentView.addSubview(paddingView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: elementsContentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: elementsContentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: elementsContentView.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 110),
            
            paddingView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            paddingView.leadingAnchor.constraint(equalTo: elementsContentView.leadingAnchor),
            paddingView.trailingAnchor.constraint(equalTo: elementsContentView.trailingAnchor),
            paddingView.bottomAnchor.constraint(equalTo: elementsContentView.bottomAnchor, constant: 20),
            
            descLabel.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: padding),
            descLabel.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: padding),
            descLabel.trailingAnchor.constraint(equalTo: paddingView.trailingAnchor, constant: -padding),
            descLabel.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func createElementView(name: String, icon: String, color: UIColor?, percentage: Double) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon circle
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = color
        iconContainer.layer.cornerRadius = 30
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .darkGray
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        // Label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = name
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .darkGray
        
        // Progress bar
        let progressBar = UIView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.backgroundColor = .systemGray5
        progressBar.layer.cornerRadius = 2
        
        let progressFill = UIView()
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = color?.withAlphaComponent(0.8) ?? .systemGray
        progressFill.layer.cornerRadius = 2
        progressBar.addSubview(progressFill)
        
        container.addSubview(iconContainer)
        container.addSubview(label)
        container.addSubview(progressBar)
        
        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            
            label.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            progressBar.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            progressBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: percentage)
        ])
        
        return container
    }
    
    private func setupMapContent() {
        let emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "Map visualization will appear here"
        emptyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.textColor = .systemGray
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        mapContentView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.topAnchor.constraint(equalTo: mapContentView.topAnchor, constant: 40),
            emptyLabel.leadingAnchor.constraint(equalTo: mapContentView.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: mapContentView.trailingAnchor, constant: -20),
            emptyLabel.bottomAnchor.constraint(equalTo: mapContentView.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupDoneButton() {
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.backgroundColor = gradientStartColor
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 25
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Data Loading
    private func loadPlaceholderData() {
        // When backend is ready, use scanResult data instead
        // For now, we're using hardcoded values displayed in setupInfoCards and setupTipsContent
    }
    
    // MARK: - Tab Actions
    @objc private func didTapTips() {
        showTab(.tips)
    }
    
    @objc private func didTapElements() {
        showTab(.elements)
    }
    
    @objc private func didTapMap() {
        showTab(.map)
    }
    
    private func showTab(_ tab: Tab) {
        currentTab = tab
        
        // Update button styles
        [tipsButton, elementsButton, mapButton].forEach { button in
            var config = button.configuration
            config?.baseForegroundColor = .darkGray
            button.configuration = config
            button.backgroundColor = .clear
        }
        
        // Highlight selected tab
        let selectedButton: UIButton
        switch tab {
        case .tips:
            selectedButton = tipsButton
        case .elements:
            selectedButton = elementsButton
        case .map:
            selectedButton = mapButton
        }
        
        var selectedConfig = selectedButton.configuration
        selectedConfig?.baseForegroundColor = gradientStartColor
        selectedButton.configuration = selectedConfig
        selectedButton.backgroundColor = .white
        
        // Show/hide content views
        tipsContentView.isHidden = tab != .tips
        elementsContentView.isHidden = tab != .elements
        mapContentView.isHidden = tab != .map
        
        // Update content view bottom constraint
        var bottomView: UIView
        switch tab {
        case .tips:
            bottomView = tipsContentView
        case .elements:
            bottomView = elementsContentView
        case .map:
            bottomView = mapContentView
        }
        
        contentView.subviews.forEach { view in
            view.constraints.forEach { constraint in
                if constraint.firstAttribute == .bottom && constraint.firstItem as? UIView == contentView {
                    constraint.isActive = false
                }
            }
        }
        
        contentView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: 100).isActive = true
    }
    
    @objc func didTapDone() {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
