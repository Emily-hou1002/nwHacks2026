import UIKit
import QuickLook

class ProcessingViewController: UIViewController {
    
    // Variables passed from ViewController
    var usdzURL: URL?
    var jsonURL: URL?
    
    // UI Elements
    let statusLabel = UILabel()
    let uploadStatusLabel = UILabel() // NEW: To show server connection status
    let exportButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Scan Complete"
        
        setupUI()
        
        // AUTOMATICALLY UPLOAD ON LOAD
        uploadFilesToServer()
    }
    
    func setupUI() {
        // 1. Success Icon
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Main Status Label
        statusLabel.text = "Feng Shui Data Ready"
        statusLabel.font = .systemFont(ofSize: 24, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Upload Status Label (NEW)
        uploadStatusLabel.text = "Attempting to upload to server..."
        uploadStatusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        uploadStatusLabel.textColor = .secondaryLabel
        uploadStatusLabel.textAlignment = .center
        uploadStatusLabel.numberOfLines = 0
        uploadStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. Export Button
        exportButton.setTitle("Export JSON & USDZ", for: .normal)
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 10
        exportButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(shareFiles), for: .touchUpInside)
        
        // Add to View
        view.addSubview(iconView)
        view.addSubview(statusLabel)
        view.addSubview(uploadStatusLabel)
        view.addSubview(exportButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            statusLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Upload Status Label Constraints
            uploadStatusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            uploadStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            uploadStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 220),
            exportButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Networking
    func uploadFilesToServer() {
        guard let usdzURL = usdzURL, let jsonURL = jsonURL else {
            self.uploadStatusLabel.text = "Error: Missing files to upload."
            return
        }

        // ⚠️ REPLACE THIS with your ngrok URL or Laptop IP
        // Example: "http://192.168.1.5:8000/upload" or "https://abc.ngrok.io/upload"
        guard let serverURL = URL(string: "https://runnier-shaniqua-yeasty.ngrok-free.dev/analyze-room") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Helper to append file data
        func appendFile(url: URL, fieldName: String) {
            if let fileData = try? Data(contentsOf: url) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(url.lastPathComponent)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        appendFile(url: jsonURL, fieldName: "room_json")
        appendFile(url: usdzURL, fieldName: "room_usdz")
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send Request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.uploadStatusLabel.text = "Upload Failed: \(error.localizedDescription)"
                    self?.uploadStatusLabel.textColor = .systemRed
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.uploadStatusLabel.text = "Successfully uploaded to server!"
                    self?.uploadStatusLabel.textColor = .systemGreen
                } else {
                    self?.uploadStatusLabel.text = "Server Error (Check logs)"
                    self?.uploadStatusLabel.textColor = .systemOrange
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Actions
    @objc func shareFiles() {
        guard let modelURL = usdzURL, let dataURL = jsonURL else {
            print("Missing file URLs")
            return
        }
        
        let items: [Any] = [modelURL, dataURL]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
}
