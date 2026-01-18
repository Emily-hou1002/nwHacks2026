import UIKit

// MARK: - Updated Scan Setup View Controller
class ScanSetupViewController: UIViewController {
    
    // MARK: - Data Storage
    private var selectedRoomType: String?
    private var selectedRoomStyle: String?
    private var selectedIntention: String?
    private var selectedBirthDate: Date?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Room Setup"
        
        // Start with room type selection
        showRoomTypeSelection()
    }
    
    // MARK: - Step 1: Room Type
    private func showRoomTypeSelection() {
        let roomTypeVC = BaguaSelectionViewController(selectionType: .roomType)
        roomTypeVC.onSelection = { [weak self] selectedType in
            self?.selectedRoomType = selectedType
            self?.showRoomStyleSelection()
        }
        navigationController?.pushViewController(roomTypeVC, animated: true)
    }
    
    // MARK: - Step 2: Room Style
    private func showRoomStyleSelection() {
        let roomStyleVC = BaguaSelectionViewController(selectionType: .roomStyle)
        roomStyleVC.onSelection = { [weak self] selectedStyle in
            self?.selectedRoomStyle = selectedStyle
            self?.showIntentionSelection()
        }
        navigationController?.pushViewController(roomStyleVC, animated: true)
    }
    
    // MARK: - Step 3: Intention
    private func showIntentionSelection() {
        let intentionVC = BaguaSelectionViewController(selectionType: .intention)
        intentionVC.onSelection = { [weak self] selectedIntention in
            self?.selectedIntention = selectedIntention
            self?.showBirthDateSelection()
        }
        navigationController?.pushViewController(intentionVC, animated: true)
    }
    
    // MARK: - Step 4: Birth Date
    private func showBirthDateSelection() {
        let birthDateVC = BirthDateViewController()
        birthDateVC.onDateSelection = { [weak self] selectedDate in
            self?.selectedBirthDate = selectedDate
            self?.proceedToScanning()
        }
        navigationController?.pushViewController(birthDateVC, animated: true)
    }
    
    // MARK: - Final Step: Start Scanning
    private func proceedToScanning() {
        guard let roomType = selectedRoomType,
              let roomStyle = selectedRoomStyle,
              let intention = selectedIntention,
              let birthDate = selectedBirthDate else {
            print("Error: Missing required data")
            return
        }
        
        let scanData = ScanData(
            roomType: roomType,
            roomStyle: roomStyle,
            intention: intention,
            birthDate: birthDate
        )
        
        let scannerVC = ViewController()
        scannerVC.config = scanData
        navigationController?.pushViewController(scannerVC, animated: true)
    }
}

// MARK: - Birth Date View Controller
class BirthDateViewController: UIViewController {
    
    var onDateSelection: ((Date) -> Void)?
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let continueButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Title
        titleLabel.text = "When were you born?"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = ""
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Date Picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        
        // Set default date to 30 years ago
        let calendar = Calendar.current
        if let defaultDate = calendar.date(byAdding: .year, value: -30, to: Date()) {
            datePicker.date = defaultDate
        }
        
        // Style the date picker for dark mode
        datePicker.setValue(UIColor.white, forKey: "textColor")
        datePicker.overrideUserInterfaceStyle = .dark
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        // Continue Button
        continueButton.setTitle("Continue to Scan", for: .normal)
        continueButton.backgroundColor = .black
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.layer.cornerRadius = 12
        continueButton.layer.borderWidth = 1.0 // Adjust the thickness as needed
        continueButton.layer.borderColor = UIColor.white.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
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
            
            // Date Picker (centered)
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Continue Button
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func didTapContinue() {
        onDateSelection?(datePicker.date)
    }
}
