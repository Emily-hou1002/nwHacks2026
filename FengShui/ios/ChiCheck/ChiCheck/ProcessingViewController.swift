import UIKit
import QuickLook
import SceneKit // Required for 3D

class ProcessingViewController: UIViewController {
    
    // MARK: - Data Variables
    var usdzURL: URL?
    var jsonURL: URL?
    var scanData: ScanData? // Needed to generate the final report
    
    // MARK: - UI Elements
    private let sceneView = SCNView() // The 3D Background
    private let overlayView = UIView() // Darkens the background for text readability
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let exportButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set view background to black so the dark scene blends seamlessly
        view.backgroundColor = .black
        title = "Processing Scan"
        navigationItem.hidesBackButton = true // Prevent going back while uploading
        
        // 1. Setup the 3D Background (Visuals)
        setup3DBackground()
        
        // 2. Setup the UI Overlay (Labels & Buttons)
        setupOverlayUI()
        
        // 3. Start the Work (Upload)
        uploadFilesToServer()
    }
    
    // MARK: - 3D Background Logic
    func setup3DBackground() {
        // Layout SceneView
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.allowsCameraControl = false
        // CRITICAL CHANGE 1: Black background for drama
        sceneView.backgroundColor = .black
        // CRITICAL CHANGE 2: Disable default lights so ONLY our gold light works
        sceneView.autoenablesDefaultLighting = false
        
        // Insert at index 0 so it is behind everything
        view.insertSubview(sceneView, at: 0)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Load the USDZ file
        let sceneToLoad: SCNScene?
        if let url = usdzURL, let scene = try? SCNScene(url: url, options: nil) {
            sceneToLoad = scene
        } else if let fallbackScene = SCNScene(named: "Room.usdz") {
             // Fallback for simulator/testing if the scanned URL fails
            sceneToLoad = fallbackScene
        } else {
            // Ultimate fallback if Room.usdz is missing
            sceneToLoad = SCNScene(named: "chair.usdz")
        }
        
        if let scene = sceneToLoad {
            // Add our custom lighting BEFORE setting up the orbit
            addGoldenEnergyLighting(to: scene)
            setupOrbit(scene: scene)
        }
    }
    
    // MARK: - NEW: Golden Energy Lighting
    func addGoldenEnergyLighting(to scene: SCNScene) {
        // 1. Define the Golden Color (Warm, bright gold)
        let goldColor = UIColor(red: 1.0, green: 0.75, blue: 0.4, alpha: 1.0)
        
        // 2. Create the Light Node
        let energySourceNode = SCNNode()
        // Position it off-center to simulate coming from a "door" relative to the model.
        // Adjust X,Y,Z here if the light needs to move closer/further from your specific model.
        energySourceNode.position = SCNVector3(x: 1.6, y: 0, z: -3)
        
        // 3. Create the Actual Light (Omni = glowing ball of light)
        let light = SCNLight()
        light.type = .omni
        light.color = goldColor
        // High intensity because it's the ONLY light in darkness
        light.intensity = 10
        // Attenuation makes the light fall off, creating pockets of shadow further away
        light.attenuationStartDistance = 0.1
        light.attenuationEndDistance = 15.0
        energySourceNode.light = light
        
        // 4. Create the "Visual" glowing cloud representation
        // This adds a bright glowing sphere at the source of the light so you can see where it's coming from.
        let sphereGeo = SCNSphere(radius: 0) // Small glowing orb
        let sphereMat = SCNMaterial()
        // Emission makes it glow even without other lights hitting it
        sphereMat.emission.contents = goldColor
        // Set diffuse to black so it doesn't reflect other light, just emits its own
        sphereMat.diffuse.contents = UIColor.black
        sceneView.prepare([sphereMat], completionHandler: nil)
        sphereGeo.materials = [sphereMat]
        
        let cloudVisualNode = SCNNode(geometry: sphereGeo)
        // Attach the visual orb to the light source node
        energySourceNode.addChildNode(cloudVisualNode)
        
        // 5. Add the energy source to the scene
        scene.rootNode.addChildNode(energySourceNode)
    }
    
    func setupOrbit(scene: SCNScene) {
        sceneView.scene = scene
        
        // Rotate the object indefinitely
        // Note: We rotate the rootNode of the imported USDZ.
        // If your model is static, ensure the USDZ itself isn't wrapped awkwardly.
        let rotateAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 20) // Slower rotation (20s) looks more epic
        let repeatAction = SCNAction.repeatForever(rotateAction)
        scene.rootNode.runAction(repeatAction)
    }
    
    // MARK: - UI Setup
    func setupOverlayUI() {
        // Dark Overlay - Lighter now since the scene itself is dark
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Activity Indicator
        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Status Label
        statusLabel.text = "Uploading & Analyzing Energy..."
        statusLabel.font = .systemFont(ofSize: 20, weight: .bold)
        // Give the text a slight shadow to pop against the glow
        statusLabel.shadowColor = UIColor.black.withAlphaComponent(0.8)
        statusLabel.shadowOffset = CGSize(width: 1, height: 1)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Export Button (Hidden initially)
        exportButton.setTitle("Export Files Manually", for: .normal)
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 10
        exportButton.isHidden = true
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(shareFiles), for: .touchUpInside)
        view.addSubview(exportButton)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 220),
            exportButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Networking
        func uploadFilesToServer() {
            guard let jsonURL = jsonURL else {
                self.showError("Missing JSON file.")
                return
            }

            // ⚠️ REPLACE WITH YOUR SERVER URL
            guard let serverURL = URL(string: "https://runnier-shaniqua-yeasty.ngrok-free.dev/analyze-room") else { return }
            
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            
            // CHANGED: Send as pure JSON, not a form file
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                // Read the data directly from the file and set it as the body
                let jsonData = try Data(contentsOf: jsonURL)
                request.httpBody = jsonData
            } catch {
                self.showError("Failed to read JSON file: \(error.localizedDescription)")
                return
            }
            
            print("🚀 Starting Raw JSON Upload...")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError("Connection Error: \(error.localizedDescription)")
                        return
                    }
                    
                    // Debug: Print what the server sent back
                    if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                        print("📩 Server Response: \(responseStr)")
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        self?.showError("Server Error \(code). See logs.")
                        return
                    }
                    
                    // SUCCESS
                    self?.handleServerResponse(data: data)
                }
            }
            task.resume()
        }
    // MARK: - Completion Logic
        func handleServerResponse(data: Data?) {
            guard let data = data else {
                showError("No data received from server.")
                return
            }
            
            do {
                // 1. Decode the JSON into our new Swift Struct
                let decoder = JSONDecoder()
                let result = try decoder.decode(ScanResult.self, from: data)
                
                // 2. Pass it to the Results Page
                let resultsVC = ResultsViewController()
                resultsVC.scanResult = result // We will add this variable in Step 3
                resultsVC.scanData = scanData // Keep original user inputs too
                
                navigationController?.pushViewController(resultsVC, animated: true)
                
            } catch {
                print("Parsing Error: \(error)")
                // Fallback: Try to print raw string if parsing fails
                if let str = String(data: data, encoding: .utf8) {
                    print("Raw Response causing error: \(str)")
                }
                showError("Could not parse server results.")
            }
        }
    
    func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        activityIndicator.stopAnimating()
        exportButton.isHidden = false
    }
    
    func generateFallbackReport() -> String {
        return "We uploaded your scan, but didn't receive a text response. Based on your intention of '\(scanData?.intention ?? "General")', check room corners for stagnation."
    }
    
    // MARK: - Actions
    @objc func shareFiles() {
        guard let modelURL = usdzURL, let dataURL = jsonURL else { return }
        let items: [Any] = [modelURL, dataURL]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = exportButton
        }
        present(activityVC, animated: true)
    }
}

// MARK: - SwiftUI Preview
import SwiftUI

#Preview {
    // 1. Create the controller
    let vc = ProcessingViewController()
    
    // 2. Inject Dummy Data for the Preview
    vc.scanData = ScanData(
        roomType: "Living Room",
        roomStyle: "Modern",
        intention: "Wealth",
        birthDate: Date()
    )
    
    // 3. Optional: Inject a dummy file URL if you have one,
    // otherwise the controller's internal fallback (chair/room) will trigger.
    if let localURL = Bundle.main.url(forResource: "Room", withExtension: "usdz") {
        vc.usdzURL = localURL
    }
    
    // 4. Return the controller to the canvas
    return vc
}
