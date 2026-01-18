import UIKit

class ScanSetupViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    // MARK: - UI Components
    private let roomTypeField = UITextField()
    private let roomStyleField = UITextField()
    private let intentionField = UITextField()
    private let dateField = UITextField()
    private let nextButton = UIButton(type: .system)
    
    // NEW: Debug Button
    private let debugSkipButton = UIButton(type: .system)
    
    // MARK: - Data Sources
    private let roomTypes = ["Bedroom",  "Living Room", "Office", "Kitchen", "Dining Room", "Bathroom", "Meditation Room"]
    private let roomStyles = ["Traditional", "Minimalist", "Modern", "Bohemian", "Industrial"]
    private let intentions = ["Creativity", "Balance", "Knowledge", "Wealth", "Health", "Love"]
    
    // MARK: - Pickers
    private let typePicker = UIPickerView()
    private let stylePicker = UIPickerView()
    private let intentionPicker = UIPickerView()
    private let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Room Details"
        
        setupUI()
        setupInputViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        func configureField(_ field: UITextField, placeholder: String) {
            field.placeholder = placeholder
            field.borderStyle = .roundedRect
            field.translatesAutoresizingMaskIntoConstraints = false
            field.delegate = self
        }
        
        configureField(roomTypeField, placeholder: "Select Room Type")
        configureField(roomStyleField, placeholder: "Select Room Style")
        configureField(intentionField, placeholder: "Feng Shui Intention")
        configureField(dateField, placeholder: "Birth Date (for Kua #)")
        
        // Main Continue Button
        nextButton.setTitle("Continue to Scan", for: .normal)
        nextButton.backgroundColor = .systemGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        
        // NEW: Debug Skip Button
        debugSkipButton.setTitle("DEBUG: Skip to Processing (Load Room.usdz)", for: .normal)
        debugSkipButton.setTitleColor(.systemRed, for: .normal)
        debugSkipButton.titleLabel?.font = .systemFont(ofSize: 14)
        debugSkipButton.translatesAutoresizingMaskIntoConstraints = false
        debugSkipButton.addTarget(self, action: #selector(didTapDebugSkip), for: .touchUpInside)
        
        // Stack View
        let stack = UIStackView(arrangedSubviews: [
            createLabel("What type of room is this?"),
            roomTypeField,
            createLabel("What is the interior style?"),
            roomStyleField,
            createLabel("What is your intention?"),
            intentionField,
            createLabel("When were you born?"),
            dateField,
            nextButton,
            debugSkipButton // Add debug button to stack
        ])
        
        stack.axis = .vertical
        stack.spacing = 15
        stack.setCustomSpacing(30, after: dateField)
        stack.setCustomSpacing(20, after: nextButton) // Space between main button and debug
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func setupInputViews() {
        roomTypeField.inputView = typePicker
        roomStyleField.inputView = stylePicker
        intentionField.inputView = intentionPicker
        dateField.inputView = datePicker
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        typePicker.delegate = self; typePicker.dataSource = self
        stylePicker.delegate = self; stylePicker.dataSource = self
        intentionPicker.delegate = self; intentionPicker.dataSource = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton], animated: false)
        
        roomTypeField.inputAccessoryView = toolbar
        roomStyleField.inputAccessoryView = toolbar
        intentionField.inputAccessoryView = toolbar
        dateField.inputAccessoryView = toolbar
    }
    
    // MARK: - Actions
    
    @objc func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateField.text = formatter.string(from: datePicker.date)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func didTapNext() {
        guard let type = roomTypeField.text, !type.isEmpty,
              let style = roomStyleField.text, !style.isEmpty,
              let intention = intentionField.text, !intention.isEmpty,
              let _ = dateField.text else {
            let alert = UIAlertController(title: "Missing Info", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let data = ScanData(roomType: type, roomStyle: style, intention: intention, birthDate: datePicker.date)
        
        let scannerVC = ViewController()
        scannerVC.config = data
        navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    // MARK: - NEW DEBUG ACTION
    @objc func didTapDebugSkip() {
        print("DEBUG: Skipping scan, loading Room.usdz...")
        
        // 1. Create Dummy Data (since the form might be empty)
        let dummyData = ScanData(
            roomType: "Debug Room",
            roomStyle: "Debug Style",
            intention: "Testing",
            birthDate: Date()
        )
        
        // 2. Initialize Processing View Controller
        let processingVC = ProcessingViewController()
        processingVC.scanData = dummyData
        
        // 3. Look for 'Room.usdz' in the App Bundle
        if let localURL = Bundle.main.url(forResource: "Room", withExtension: "usdz") {
            processingVC.usdzURL = localURL
            // Optional: Pass a dummy JSON if your processing script requires it, or handle nil safely
            processingVC.jsonURL = Bundle.main.url(forResource: "Room", withExtension: "json")
        } else {
            print("⚠️ WARNING: Could not find 'Room.usdz' in the project bundle.")
            // The ProcessingViewController has fallback logic (the chair), so it won't crash,
            // but you should drag a file named "Room.usdz" into Xcode to see it.
        }
        
        // 4. Go there
        navigationController?.pushViewController(processingVC, animated: true)
    }
    
    // MARK: - PickerView DataSource & Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == typePicker { return roomTypes.count }
        if pickerView == stylePicker { return roomStyles.count }
        if pickerView == intentionPicker { return intentions.count }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == typePicker { return roomTypes[row] }
        if pickerView == stylePicker { return roomStyles[row] }
        if pickerView == intentionPicker { return intentions[row] }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == typePicker { roomTypeField.text = roomTypes[row] }
        if pickerView == stylePicker { roomStyleField.text = roomStyles[row] }
        if pickerView == intentionPicker { intentionField.text = intentions[row] }
    }
}
