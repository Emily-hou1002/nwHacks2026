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
    
    // MARK: - Color Palette
    private let babyBlue = UIColor(hex: "8FFBFF") ?? UIColor.systemBlue
    private let babyYellow = UIColor(hex: "FFEA8F") ?? UIColor.systemYellow
    private let mint = UIColor(hex: "8FFF9A") ?? UIColor.systemGreen
    private let gradientStartColor = UIColor(hex: "0066FF") ?? UIColor.systemBlue
    private let gradientEndColor = UIColor(hex: "00CC99") ?? UIColor.systemTeal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = "Your Energy Map"
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
        contentView.addSubview(headerView)
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
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
        titleLabel.text = "Your Feng Shui Score"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 50),
            logoImageView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupScoreAndFocusCards() {
        // Score Card
        setupCard(scoreCard, backgroundColor: babyBlue.withAlphaComponent(0.3))
        scoreLabel.text = "Overall Score"
        scoreLabel.font = .systemFont(ofSize: 16, weight: .regular)
        scoreLabel.textColor = .darkGray
        scoreLabel.textAlignment = .center
        
        scoreValueLabel.text = "85"
        scoreValueLabel.font = .systemFont(ofSize: 48, weight: .bold)
        scoreValueLabel.textColor = gradientStartColor
        scoreValueLabel.textAlignment = .center
        
        scoreCard.addSubview(scoreLabel)
        scoreCard.addSubview(scoreValueLabel)
        
        // Focus Card
        setupCard(focusCard, backgroundColor: mint.withAlphaComponent(0.3))
        focusLabel.text = "Your Focus"
        focusLabel.font = .systemFont(ofSize: 16, weight: .regular)
        focusLabel.textColor = .darkGray
        focusLabel.textAlignment = .center
        
        focusValueLabel.text = "Creativity"
        focusValueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        focusValueLabel.textColor = UIColor(hex: "00AA66")
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
        card.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    private func setupBaguaZones() {
        baguaZonesContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(baguaZonesContainer)
        
        // Section Title
        baguaZonesLabel.translatesAutoresizingMaskIntoConstraints = false
        baguaZonesLabel.text = "Energy Zones"
        baguaZonesLabel.font = .systemFont(ofSize: 22, weight: .bold)
        baguaZonesLabel.textColor = .darkGray
        baguaZonesContainer.addSubview(baguaZonesLabel)
        
        // Placeholder bagua zones - will be replaced with backend data
        let zones = [
            ("Health", "bed.double.fill", 0.85, mint),
            ("Wealth", "dollarsign.circle.fill", 0.65, babyYellow),
            ("Love", "heart.fill", 0.75, UIColor.systemPink.withAlphaComponent(0.3)),
            ("Career", "briefcase.fill", 0.80, babyBlue),
            ("Family", "house.fill", 0.70, UIColor.systemGreen.withAlphaComponent(0.3)),
            ("Knowledge", "book.fill", 0.90, UIColor.systemIndigo.withAlphaComponent(0.3)),
            ("Fame", "flame.fill", 0.60, UIColor.systemRed.withAlphaComponent(0.3)),
            ("Children", "figure.2.and.child.holdinghands", 0.75, babyYellow),
            ("Travel", "airplane", 0.70, babyBlue)
        ]
        
        var previousView: UIView = baguaZonesLabel
        
        for (index, zone) in zones.enumerated() {
            let zoneCard = createZoneCard(name: zone.0, icon: zone.1, progress: zone.2, color: zone.3)
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
    
    private func createZoneCard(name: String, icon: String, progress: Double, color: UIColor) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Icon with background circle
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = color
        iconContainer.layer.cornerRadius = 25
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .darkGray
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        // Zone Name
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .darkGray
        
        // Progress Container
        let progressContainer = UIView()
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.backgroundColor = UIColor.systemGray6
        progressContainer.layer.cornerRadius = 10
        
        let progressBar = UIView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.backgroundColor = color.withAlphaComponent(0.8)
        progressBar.layer.cornerRadius = 10
        progressContainer.addSubview(progressBar)
        
        // Progress percentage label
        let percentLabel = UILabel()
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        percentLabel.text = "\(Int(progress * 100))%"
        percentLabel.font = .systemFont(ofSize: 14, weight: .medium)
        percentLabel.textColor = .darkGray
        
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
        continueButton.setTitle("View Harmonic Suggestions", for: .normal)
        continueButton.backgroundColor = gradientStartColor
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 25
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            
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
