import UIKit

class ScanSetupViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    // MARK: - UI Components
    private let roomTypeField = UITextField()
    private let roomStyleField = UITextField()
    private let intentionField = UITextField()
    private let dateField = UITextField()
    private let nextButton = UIButton(type: .system)
    
    // MARK: - Data Sources
    private let roomTypes = ["Bedroom", "Office", "Living Room", "Kitchen", "Bathroom"]
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
        
        // Dismiss keyboard gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Helper to style fields
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
        
        // Configure Button
        nextButton.setTitle("Continue to Scan", for: .normal)
        nextButton.backgroundColor = .systemGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        
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
            nextButton
        ])
        
        stack.axis = .vertical
        stack.spacing = 15
        stack.setCustomSpacing(30, after: dateField)
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
        // Assign pickers to text fields
        roomTypeField.inputView = typePicker
        roomStyleField.inputView = stylePicker
        intentionField.inputView = intentionPicker
        dateField.inputView = datePicker
        
        // Setup Date Picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        // Setup Delegates
        typePicker.delegate = self; typePicker.dataSource = self
        stylePicker.delegate = self; stylePicker.dataSource = self
        intentionPicker.delegate = self; intentionPicker.dataSource = self
        
        // Toolbar
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
        // Validate Inputs
        guard let type = roomTypeField.text, !type.isEmpty,
              let style = roomStyleField.text, !style.isEmpty,
              let intention = intentionField.text, !intention.isEmpty,
              let _ = dateField.text else {
            let alert = UIAlertController(title: "Missing Info", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Create Data Object
        let data = ScanData(
            roomType: type,
            roomStyle: style,
            intention: intention,
            birthDate: datePicker.date
        )
        
        // Navigate to Scanner
        let scannerVC = ViewController()
        scannerVC.config = data
        navigationController?.pushViewController(scannerVC, animated: true)
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
