import UIKit

class BaguaResultsViewController: UIViewController {

    // MARK: - Data Properties
    var scanResult: ScanResult? // Backend data (when ready)
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    
    // Score Card
    private let scoreCard = UIView()
    private let scoreLabel = UILabel()
    private let scoreValueLabel = UILabel()
    
    // Focus Card
    private let focusCard = UIView()
    private let focusLabel = UILabel()
    private let focusValueLabel = UILabel()
    
    // Bagua Zones Container
    private let baguaZonesContainer = UIView()
    private let baguaZonesLabel = UILabel()
    
    // Continue Button
    private let continueButton = UIButton(type: .system)
    
    // MARK: - Color Palette (Black & Gold Zen)
    private let goldColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0) // Metallic gold
    private let darkGray = UIColor(white: 0.15, alpha: 1.0)
    private let mediumGray = UIColor(white: 0.25, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "your energy map"
        navigationItem.hidesBackButton = true
        
        setupUI()
        loadPlaceholderData()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        setupScrollView()
        setupHeader()
        setupScoreAndFocusCards()
        setupBaguaZones()
        setupContinueButton()
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
        
        // Logo
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "leaf.circle.fill")
        logoImageView.tintColor = goldColor
        headerView.addSubview(logoImageView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "your feng shui score"
        titleLabel.font = .systemFont(ofSize: 28, weight: .light)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),
            
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupScoreAndFocusCards() {
        // Score Card
        setupCard(scoreCard, backgroundColor: darkGray)
        scoreLabel.text = "overall score"
        scoreLabel.font = .systemFont(ofSize: 14, weight: .regular)
        scoreLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        scoreLabel.textAlignment = .center
        
        scoreValueLabel.text = "85"
        scoreValueLabel.font = .systemFont(ofSize: 48, weight: .light)
        scoreValueLabel.textColor = .white  // Changed from gold to white
        scoreValueLabel.textAlignment = .center
        
        scoreCard.addSubview(scoreLabel)
        scoreCard.addSubview(scoreValueLabel)
        
        // Focus Card
        setupCard(focusCard, backgroundColor: darkGray)
        focusLabel.text = "your focus"
        focusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        focusLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        focusLabel.textAlignment = .center
        
        focusValueLabel.text = "creativity"
        focusValueLabel.font = .systemFont(ofSize: 24, weight: .light)
        focusValueLabel.textColor = .white
        focusValueLabel.textAlignment = .center
        
        focusCard.addSubview(focusLabel)
        focusCard.addSubview(focusValueLabel)
        
        contentView.addSubview(scoreCard)
        contentView.addSubview(focusCard)
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreValueLabel.translatesAutoresizingMaskIntoConstraints = false
        focusLabel.translatesAutoresizingMaskIntoConstraints = false
        focusValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Score Card
            scoreCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            scoreCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scoreCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            scoreCard.heightAnchor.constraint(equalToConstant: 120),
            
            scoreLabel.topAnchor.constraint(equalTo: scoreCard.topAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            
            scoreValueLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            scoreValueLabel.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            
            // Focus Card
            focusCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            focusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            focusCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43),
            focusCard.heightAnchor.constraint(equalToConstant: 120),
            
            focusLabel.topAnchor.constraint(equalTo: focusCard.topAnchor, constant: 20),
            focusLabel.centerXAnchor.constraint(equalTo: focusCard.centerXAnchor),
            
            focusValueLabel.topAnchor.constraint(equalTo: focusLabel.bottomAnchor, constant: 8),
            focusValueLabel.leadingAnchor.constraint(equalTo: focusCard.leadingAnchor, constant: 10),
            focusValueLabel.trailingAnchor.constraint(equalTo: focusCard.trailingAnchor, constant: -10),
            focusValueLabel.centerXAnchor.constraint(equalTo: focusCard.centerXAnchor)
        ])
    }
    
    private func setupCard(_ card: UIView, backgroundColor: UIColor?) {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = backgroundColor
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
    
    private func setupBaguaZones() {
        baguaZonesContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(baguaZonesContainer)
        
        // Section Title
        baguaZonesLabel.translatesAutoresizingMaskIntoConstraints = false
        baguaZonesLabel.text = "energy zones"
        baguaZonesLabel.font = .systemFont(ofSize: 20, weight: .light)
        baguaZonesLabel.textColor = .white
        baguaZonesContainer.addSubview(baguaZonesLabel)
        
        // Placeholder bagua zones - will be replaced with backend data
        let zones = [
            ("health", "bed.double.fill", 0.85),
            ("wealth", "dollarsign.circle.fill", 0.65),
            ("love", "heart.fill", 0.75),
            ("career", "briefcase.fill", 0.80),
            ("family", "house.fill", 0.70),
            ("knowledge", "book.fill", 0.90),
            ("fame", "flame.fill", 0.60),
            ("children", "figure.2.and.child.holdinghands", 0.75),
            ("travel", "airplane", 0.70)
        ]
        
        var previousView: UIView = baguaZonesLabel
        
        for (index, zone) in zones.enumerated() {
            let zoneCard = createZoneCard(name: zone.0, icon: zone.1, progress: zone.2)
            baguaZonesContainer.addSubview(zoneCard)
            
            NSLayoutConstraint.activate([
                zoneCard.topAnchor.constraint(equalTo: index == 0 ? baguaZonesLabel.bottomAnchor : previousView.bottomAnchor, constant: index == 0 ? 20 : 12),
                zoneCard.leadingAnchor.constraint(equalTo: baguaZonesContainer.leadingAnchor),
                zoneCard.trailingAnchor.constraint(equalTo: baguaZonesContainer.trailingAnchor)
            ])
            
            previousView = zoneCard
        }
        
        NSLayoutConstraint.activate([
            baguaZonesContainer.topAnchor.constraint(equalTo: scoreCard.bottomAnchor, constant: 30),
            baguaZonesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            baguaZonesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            baguaZonesContainer.bottomAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 20),
            
            baguaZonesLabel.topAnchor.constraint(equalTo: baguaZonesContainer.topAnchor),
            baguaZonesLabel.leadingAnchor.constraint(equalTo: baguaZonesContainer.leadingAnchor)
        ])
    }
    
    private func createZoneCard(name: String, icon: String, progress: Double) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = darkGray
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        // Icon with background circle
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = mediumGray
        iconContainer.layer.cornerRadius = 25
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = UIColor.white.withAlphaComponent(0.8)  // Changed from gold to white
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        // Zone Name
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 17, weight: .regular)
        nameLabel.textColor = .white
        
        // Progress Container
        let progressContainer = UIView()
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.backgroundColor = mediumGray
        progressContainer.layer.cornerRadius = 10
        
        let progressBar = UIView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.backgroundColor = .white  // Changed from gold to white
        progressBar.layer.cornerRadius = 10
        progressContainer.addSubview(progressBar)
        
        // Progress percentage label
        let percentLabel = UILabel()
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        percentLabel.text = "\(Int(progress * 100))%"
        percentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        percentLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        
        card.addSubview(iconContainer)
        card.addSubview(nameLabel)
        card.addSubview(progressContainer)
        card.addSubview(percentLabel)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15),
            iconContainer.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 50),
            iconContainer.heightAnchor.constraint(equalToConstant: 50),
            
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            
            progressContainer.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            progressContainer.trailingAnchor.constraint(equalTo: percentLabel.leadingAnchor, constant: -10),
            progressContainer.heightAnchor.constraint(equalToConstant: 20),
            progressContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15),
            
            progressBar.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            progressBar.widthAnchor.constraint(equalTo: progressContainer.widthAnchor, multiplier: progress),
            
            percentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            percentLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            percentLabel.widthAnchor.constraint(equalToConstant: 50),
            
            card.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return card
    }
    
    private func setupContinueButton() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("view harmonic suggestions", for: .normal)
        continueButton.backgroundColor = .white  // White button
        continueButton.setTitleColor(.black, for: .normal)  // Black text
        continueButton.layer.cornerRadius = 28
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            
            contentView.bottomAnchor.constraint(equalTo: baguaZonesContainer.bottomAnchor, constant: 100)
        ])
    }
    
    // MARK: - Data Loading
    private func loadPlaceholderData() {
        // When backend is ready, use scanResult data instead
        // For now, we're using hardcoded values
    }
    
    // MARK: - Actions
    @objc private func didTapContinue() {
        let harmonicVC = HarmonicSuggestionsViewController()
        navigationController?.pushViewController(harmonicVC, animated: true)
    }
}
