import UIKit

class HarmonicSuggestionsViewController: UIViewController {

    // MARK: - Data Properties
    var scanResult: ScanResult? // Backend data (when ready)
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Tab Buttons
    private let tabContainer = UIView()
    private let suggestion1Button = UIButton(type: .system)
    private let suggestion2Button = UIButton(type: .system)
    private let suggestion3Button = UIButton(type: .system)
    
    // Content Container
    private let suggestionContentView = UIView()
    private let suggestionTitleLabel = UILabel()
    private let benefitsSectionLabel = UILabel()
    private let benefitsTextView = UITextView()
    
    // Done Button
    private let doneButton = UIButton(type: .system)
    
    // State
    private var currentSuggestion: Int = 1
    
    // MARK: - Color Palette (Black & Gold Zen)
    private let goldColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0) // Metallic gold
    private let darkGray = UIColor(white: 0.15, alpha: 1.0)
    private let mediumGray = UIColor(white: 0.25, alpha: 1.0)
    
    // Placeholder suggestions data
    private let suggestions = [
        (
            title: "place your bed in the east direction",
            benefits: "east is your best direction for health and vitality based on your kua number. aligning your bed with this direction promotes restful sleep, enhances energy levels, and supports overall wellbeing. the east represents new beginnings and the rising sun, bringing fresh chi energy into your space each morning. this placement creates a harmonious flow that resonates with growth and renewal, supporting health matters and family relationships while creating a nurturing sanctuary in your bedroom."
        ),
        (
            title: "add wooden elements to your space",
            benefits: "incorporating plants or wooden furniture enhances the wood element in your room, which is associated with growth, vitality, and creativity. wood element brings upward, expansive energy that supports personal development and abundance. natural materials create a grounding connection to nature, reducing stress and promoting tranquility. the presence of wood element creates a living, breathing atmosphere that feels fresh and invigorating, particularly beneficial for your focus on creativity as it nurtures innovative thinking and new ideas."
        ),
        (
            title: "use warm, earthy tones in your decor",
            benefits: "colors like terracotta, beige, and soft greens harmonize with your space's natural energy flow. these earth tones create psychological comfort and stability while supporting the grounding aspect of feng shui. warm colors stimulate gentle energy without being overwhelming, perfect for a bedroom retreat. earthy tones evoke feelings of security, comfort, and connection to nature, creating a cocoon-like atmosphere that helps you unwind and feel protected while supporting restful sleep."
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "harmonic suggestions"
        navigationItem.hidesBackButton = true
        
        setupUI()
        showSuggestion(1)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        setupScrollView()
        setupHeader()
        setupTabButtons()
        setupSuggestionContent()
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
        titleLabel.text = "harmonic suggestions"
        titleLabel.font = .systemFont(ofSize: 28, weight: .light)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "enhance your space's energy"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTabButtons() {
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        tabContainer.backgroundColor = darkGray
        tabContainer.layer.cornerRadius = 25
        tabContainer.layer.borderWidth = 1
        tabContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        contentView.addSubview(tabContainer)
        
        configureTabButton(suggestion1Button, number: "1")
        configureTabButton(suggestion2Button, number: "2")
        configureTabButton(suggestion3Button, number: "3")
        
        suggestion1Button.addTarget(self, action: #selector(didTapSuggestion1), for: .touchUpInside)
        suggestion2Button.addTarget(self, action: #selector(didTapSuggestion2), for: .touchUpInside)
        suggestion3Button.addTarget(self, action: #selector(didTapSuggestion3), for: .touchUpInside)
        
        tabContainer.addSubview(suggestion1Button)
        tabContainer.addSubview(suggestion2Button)
        tabContainer.addSubview(suggestion3Button)
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            tabContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabContainer.heightAnchor.constraint(equalToConstant: 50),
            
            suggestion1Button.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 10),
            suggestion1Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            suggestion1Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            
            suggestion2Button.centerXAnchor.constraint(equalTo: tabContainer.centerXAnchor),
            suggestion2Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            suggestion2Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28),
            
            suggestion3Button.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -10),
            suggestion3Button.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            suggestion3Button.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.28)
        ])
    }
    
    private func configureTabButton(_ button: UIButton, number: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.title = "tip \(number)"
        config.baseForegroundColor = UIColor.white.withAlphaComponent(0.7)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .regular)
            return outgoing
        }
        
        button.configuration = config
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
    }
    
    private func setupSuggestionContent() {
        suggestionContentView.translatesAutoresizingMaskIntoConstraints = false
        suggestionContentView.backgroundColor = darkGray
        suggestionContentView.layer.cornerRadius = 20
        suggestionContentView.layer.borderWidth = 1
        suggestionContentView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        contentView.addSubview(suggestionContentView)
        
        // Suggestion Title
        suggestionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        suggestionTitleLabel.font = .systemFont(ofSize: 20, weight: .light)
        suggestionTitleLabel.textColor = .white
        suggestionTitleLabel.numberOfLines = 0
        suggestionContentView.addSubview(suggestionTitleLabel)
        
        // Benefits Section
        benefitsSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        benefitsSectionLabel.text = "why this helps"
        benefitsSectionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        benefitsSectionLabel.textColor = goldColor
        suggestionContentView.addSubview(benefitsSectionLabel)
        
        benefitsTextView.translatesAutoresizingMaskIntoConstraints = false
        benefitsTextView.font = .systemFont(ofSize: 15, weight: .regular)
        benefitsTextView.textColor = UIColor.white.withAlphaComponent(0.9)
        benefitsTextView.isEditable = false
        benefitsTextView.isScrollEnabled = false
        benefitsTextView.backgroundColor = mediumGray
        benefitsTextView.layer.cornerRadius = 12
        benefitsTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        suggestionContentView.addSubview(benefitsTextView)
        
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
            benefitsTextView.bottomAnchor.constraint(equalTo: suggestionContentView.bottomAnchor, constant: -25)
        ])
    }
    
    private func setupDoneButton() {
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("done", for: .normal)
        doneButton.backgroundColor = .white  // White button
        doneButton.setTitleColor(.black, for: .normal)  // Black text
        doneButton.layer.cornerRadius = 28
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.heightAnchor.constraint(equalToConstant: 56),
            
            contentView.bottomAnchor.constraint(equalTo: suggestionContentView.bottomAnchor, constant: 100)
        ])
    }
    
    // MARK: - Tab Actions
    @objc private func didTapSuggestion1() {
        showSuggestion(1)
    }
    
    @objc private func didTapSuggestion2() {
        showSuggestion(2)
    }
    
    @objc private func didTapSuggestion3() {
        showSuggestion(3)
    }
    
    private func showSuggestion(_ suggestionNumber: Int) {
        currentSuggestion = suggestionNumber
        
        // Update button styles
        [suggestion1Button, suggestion2Button, suggestion3Button].forEach { button in
            var config = button.configuration
            config?.baseForegroundColor = UIColor.white.withAlphaComponent(0.7)
            button.configuration = config
            button.backgroundColor = .clear
        }
        
        // Highlight selected tab
        let selectedButton: UIButton
        switch suggestionNumber {
        case 1:
            selectedButton = suggestion1Button
        case 2:
            selectedButton = suggestion2Button
        case 3:
            selectedButton = suggestion3Button
        default:
            selectedButton = suggestion1Button
        }
        
        var selectedConfig = selectedButton.configuration
        selectedConfig?.baseForegroundColor = goldColor
        selectedButton.configuration = selectedConfig
        selectedButton.backgroundColor = mediumGray
        
        // Update content
        let suggestion = suggestions[suggestionNumber - 1]
        suggestionTitleLabel.text = suggestion.title
        benefitsTextView.text = suggestion.benefits
        
        // Animate content change
        UIView.animate(withDuration: 0.2) {
            self.suggestionContentView.alpha = 0.0
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.suggestionContentView.alpha = 1.0
            }
        }
    }
    
    @objc func didTapDone() {
        navigationController?.popToRootViewController(animated: true)
    }
}
