import UIKit

// MARK: - Selection Option Model
struct SelectionOption {
    let title: String
    let icon: String // SF Symbol name
    let description: String?
}

// MARK: - Selection Type Enum
enum SelectionType {
    case roomType
    case roomStyle
    case intention
    
    var title: String {
        switch self {
        case .roomType: return "What type of room is this?"
        case .roomStyle: return "What is the interior style?"
        case .intention: return "What is your intention?"
        }
    }
    
    var options: [SelectionOption] {
        switch self {
        case .roomType:
            return [
                SelectionOption(title: "bedroom", icon: "bed.double.fill", description: "rest & rejuvenation"),
                SelectionOption(title: "living room", icon: "sofa.fill", description: "gathering & connection"),
                SelectionOption(title: "office", icon: "table.furniture.fill", description: "focus & productivity"),
                SelectionOption(title: "kitchen", icon: "fork.knife", description: "nourishment & abundance"),
                SelectionOption(title: "dining room", icon: "table.furniture.fill", description: "unity & togetherness"),
                SelectionOption(title: "bathroom", icon: "drop.fill", description: "cleansing & renewal"),
                SelectionOption(title: "meditation room", icon: "figure.mind.and.body", description: "peace & clarity")
            ]
        case .roomStyle:
            return [
                SelectionOption(title: "traditional", icon: "building.columns.fill", description: "timeless & elegant"),
                SelectionOption(title: "minimalist", icon: "square.3.layers.3d", description: "simple & clean"),
                SelectionOption(title: "modern", icon: "lightbulb.fill", description: "contemporary & bold"),
                SelectionOption(title: "bohemian", icon: "paintpalette.fill", description: "free & eclectic"),
                SelectionOption(title: "industrial", icon: "gearshape.2.fill", description: "raw & urban")
            ]
        case .intention:
            return [
                SelectionOption(title: "creativity", icon: "sparkles", description: "inspiration & expression"),
                SelectionOption(title: "balance", icon: "circle.lefthalf.filled", description: "harmony & peace"),
                SelectionOption(title: "knowledge", icon: "book.fill", description: "wisdom & qrowth"),
                SelectionOption(title: "wealth", icon: "dollarsign.circle.fill", description: "abundance & prosperity"),
                SelectionOption(title: "health", icon: "heart.fill", description: "vitality & wellness"),
                SelectionOption(title: "love", icon: "heart.circle.fill", description: "relationships & connection")
            ]
        }
    }
}

// MARK: - Circular Selection Cell
class CircularSelectionCell: UICollectionViewCell {
    static let identifier = "CircularSelectionCell"
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container with circular border
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Description
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        descriptionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            // Container (circular)
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 100),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Icon inside circle
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Title below circle
            titleLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Description below title
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Make container circular
        containerView.layer.cornerRadius = 50
    }
    
    func configure(with option: SelectionOption, isSelected: Bool) {
        iconImageView.image = UIImage(systemName: option.icon)
        titleLabel.text = option.title
        descriptionLabel.text = option.description
        
        // Custom Gold Color
        let goldColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        
        // Update selection state
        if isSelected {
            // Highlighting with Gold instead of Green
            containerView.backgroundColor = goldColor.withAlphaComponent(0.2)
            containerView.layer.borderColor = goldColor.cgColor
            containerView.layer.borderWidth = 3
            iconImageView.tintColor = goldColor // Optional: makes the icon gold too
        } else {
            containerView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            containerView.layer.borderColor = UIColor.white.cgColor
            containerView.layer.borderWidth = 2
            iconImageView.tintColor = .white
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
    }
}

// MARK: - Bagua Selection View Controller
class BaguaSelectionViewController: UIViewController {
    
    // MARK: - Properties
    var selectionType: SelectionType
    var onSelection: ((String) -> Void)?
    private var selectedIndex: Int?
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let yinYangImageView = UIImageView()
    private var collectionView: UICollectionView!
    private let continueButton = UIButton(type: .system)
    
    // MARK: - Init
    init(selectionType: SelectionType) {
        self.selectionType = selectionType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .black
        
        // Title
        titleLabel.text = selectionType.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle with yin-yang symbol
        subtitleLabel.text = ""
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Continue Button
        continueButton.setTitle("continue", for: .normal)
        continueButton.backgroundColor = .black
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.layer.cornerRadius = 12
        continueButton.layer.borderWidth = 1.0 // Adjust the thickness as needed
        continueButton.layer.borderColor = UIColor.white.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.alpha = 0.5
        continueButton.isEnabled = true
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Continue Button
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 30
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Calculate item size (2 columns for most, 3 for intentions)
        let columns: CGFloat = selectionType == .intention ? 2 : 2
        let spacing: CGFloat = 20
        let totalSpacing = spacing * (columns + 1)
        let availableWidth = view.bounds.width - totalSpacing
        let itemWidth = availableWidth / columns
        let itemHeight: CGFloat = 170
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CircularSelectionCell.self, forCellWithReuseIdentifier: CircularSelectionCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    @objc private func didTapContinue() {
        guard let index = selectedIndex else { return }
        let selectedOption = selectionType.options[index]
        onSelection?(selectedOption.title)
    }
    
    private func updateContinueButton() {
        UIView.animate(withDuration: 0.3) {
            self.continueButton.alpha = self.selectedIndex != nil ? 1.0 : 0.5
            self.continueButton.isEnabled = self.selectedIndex != nil
        }
    }
}

// MARK: - Collection View Delegate & Data Source
extension BaguaSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectionType.options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CircularSelectionCell.identifier, for: indexPath) as? CircularSelectionCell else {
            return UICollectionViewCell()
        }
        
        let option = selectionType.options[indexPath.item]
        let isSelected = selectedIndex == indexPath.item
        cell.configure(with: option, isSelected: isSelected)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Update selection
        let previousIndex = selectedIndex
        selectedIndex = indexPath.item
        
        // Reload affected cells
        var indexPathsToReload = [indexPath]
        if let previous = previousIndex {
            indexPathsToReload.append(IndexPath(item: previous, section: 0))
        }
        
        collectionView.reloadItems(at: indexPathsToReload)
        updateContinueButton()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
