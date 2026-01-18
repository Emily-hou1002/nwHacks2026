import UIKit
import QuickLook
import SceneKit // Required for 3D

class ProcessingViewController: UIViewController {
    
    // MARK: - Data Variables
    var usdzURL: URL?
    var jsonURL: URL?
    var scanData: ScanData?
    
    // MARK: - UI Elements
    private let sceneView = SCNView()
    private let overlayView = UIView()
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let exportButton = UIButton(type: .system)
    
    // State
    private var energyCursorNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Processing Scan"
        navigationItem.hidesBackButton = true
        
        setup3DBackground()
        setupOverlayUI()
        
        // Start the Energy Animation
        startEnergySequence()
        
        uploadFilesToServer()
    }
    
    // MARK: - Energy Animation Logic
    func startEnergySequence() {
        guard let url = jsonURL else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let engine = PathfindingEngine()
            // 1. Calculate Path (Center -> Door)
            if let pathPoints = engine.calculatePath(from: url) {
                // 2. Reverse it (Door -> Center) for the "Entering" effect
                let enteringPath = Array(pathPoints.reversed())
                
                DispatchQueue.main.async {
                    self.animateFlow(points: enteringPath)
                }
            }
        }
    }
    
    func animateFlow(points: [CGPoint]) {
        guard let firstPoint = points.first else { return }
        
        // --- 1. SETUP CURSOR NODE ---
        // This node will physically travel along the path
        let cursor = SCNNode()
        let startPos = SCNVector3(firstPoint.x, 0.5, firstPoint.y) // Start 0.5m off floor
        cursor.position = startPos
        sceneView.scene?.rootNode.addChildNode(cursor)
        self.energyCursorNode = cursor
        
        // --- 2. LIGHT SETUP (Travels with cursor) ---
        let light = SCNLight()
        light.type = .omni
        let goldColor = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        light.color = goldColor
        light.intensity = 500 // Start dim
        light.attenuationEndDistance = 4.0 // Small pool of light initially
        cursor.light = light
        
        // --- 3. PARTICLE SYSTEM A: "THE STREAM" ---
        // Trail of energy entering the room
        let streamParticles = SCNParticleSystem()
        streamParticles.particleImage = createSoftParticleImage()
        streamParticles.particleColor = goldColor
        streamParticles.blendMode = .additive
        streamParticles.birthRate = 150 // Dense stream
        streamParticles.particleLifeSpan = 2.5 // Lasts long enough to leave a trail
        streamParticles.particleSize = 0.15
        streamParticles.emitterShape = SCNSphere(radius: 0.2)
        streamParticles.birthLocation = .volume
        
        // IMPORTANT: Birth in World Space so particles stay behind as cursor moves
        streamParticles.isLocal = false
        
        // Movement: Slight spread, no velocity (they hang in the air where born)
        streamParticles.particleVelocity = 0.2
        streamParticles.spreadingAngle = 180
        
        cursor.addParticleSystem(streamParticles)
        
        // --- 4. CREATE MOVEMENT ACTIONS ---
        var actions: [SCNAction] = []
        
        // Travel at constant speed (e.g., 2 meters per second)
        let speed: Double = 2.0
        
        for i in 1..<points.count {
            let pt = points[i]
            let worldPos = SCNVector3(pt.x, 0.5, pt.y)
            let dist = distanceBetween(cursor.position, worldPos)
            let duration = Double(dist) / speed
            
            let moveAction = SCNAction.move(to: worldPos, duration: duration)
            moveAction.timingMode = .linear
            actions.append(moveAction)
        }
        
        // --- 5. FINAL PHASE: "THE FILL" ---
        // When cursor reaches center (last point), trigger explosion
        let fillAction = SCNAction.run { node in
            // A. Remove the Stream
            node.removeParticleSystem(streamParticles)
            
            // B. Add "Fountain" Particles (Up and Out)
            let fountain = SCNParticleSystem()
            fountain.particleImage = self.createSoftParticleImage()
            fountain.particleColor = goldColor
            fountain.blendMode = .additive
            fountain.birthRate = 300 // Explosion!
            fountain.particleLifeSpan = 4.0
            fountain.particleSize = 0.2
            fountain.emitterShape = SCNSphere(radius: 0.5)
            fountain.birthLocation = .volume
            fountain.isLocal = true // Move with center if needed
            
            // Physics: Float UPWARDS
            fountain.acceleration = SCNVector3(0, 1.5, 0) // Negative gravity (Up)
            fountain.particleVelocity = 1.0 // Initial speed outwards
            fountain.spreadingAngle = 180 // Omnidirectional
            
            // Animation: Size Pulse
            let sizeAnim = CABasicAnimation(keyPath: "particleSize")
            sizeAnim.fromValue = 0.1
            sizeAnim.toValue = 0.4
            sizeAnim.duration = 2.0
            sizeAnim.autoreverses = true
            sizeAnim.repeatCount = .infinity
            fountain.addAnimation(sizeAnim, forKey: "sizePulse")
            
            node.addParticleSystem(fountain)
            
            // C. Animate Light to Fill Room
            // Ramp intensity up
            let intensityAnim = CABasicAnimation(keyPath: "light.intensity")
            intensityAnim.fromValue = 500
            intensityAnim.toValue = 2000
            intensityAnim.duration = 2.0
            intensityAnim.fillMode = .forwards
            intensityAnim.isRemovedOnCompletion = false
            node.addAnimation(intensityAnim, forKey: "lightUp")
            
            // Ramp range (attenuation) up to cover walls
            let rangeAnim = CABasicAnimation(keyPath: "light.attenuationEndDistance")
            rangeAnim.fromValue = 4.0
            rangeAnim.toValue = 20.0
            rangeAnim.duration = 3.0
            rangeAnim.fillMode = .forwards
            rangeAnim.isRemovedOnCompletion = false
            node.addAnimation(rangeAnim, forKey: "rangeUp")
        }
        
        actions.append(fillAction)
        
        // Execute Chain
        cursor.runAction(SCNAction.sequence(actions))
    }
    
    // Helper: Soft Particle Image
    func createSoftParticleImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: 32, height: 32)
            let path = UIBezierPath(ovalIn: rect)
            context.cgContext.addPath(path.cgPath)
            // Pure white (colorized by SceneKit)
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillPath()
        }
    }
    
    // Math Helpers
    func distanceBetween(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2) + pow(a.z - b.z, 2))
    }
    
    // MARK: - 3D Background Logic
    func setup3DBackground() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = false
        
        view.insertSubview(sceneView, at: 0)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let sceneToLoad: SCNScene?
        if let url = usdzURL, let scene = try? SCNScene(url: url, options: nil) {
            sceneToLoad = scene
        } else if let fallbackScene = SCNScene(named: "Room.usdz") {
            sceneToLoad = fallbackScene
        } else {
            sceneToLoad = SCNScene(named: "chair.usdz")
        }
        
        if let scene = sceneToLoad {
            setupOrbit(scene: scene)
        }
    }
    
    func setupOrbit(scene: SCNScene) {
        sceneView.scene = scene
        
        let cameraRig = SCNNode()
        cameraRig.position = SCNVector3(0, 0, 0)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Wide high angle view
        cameraNode.position = SCNVector3(0, 8, 8)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        
        cameraRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraRig)
        
        sceneView.pointOfView = cameraNode
        
        let rotateAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 30)
        let repeatAction = SCNAction.repeatForever(rotateAction)
        cameraRig.runAction(repeatAction)
    }
    
    // MARK: - Networking
    func uploadFilesToServer() {
        guard let jsonURL = jsonURL else {
            self.showError("Missing JSON file.")
            return
        }
        guard let serverURL = URL(string: "https://runnier-shaniqua-yeasty.ngrok-free.dev/analyze-room") else { return }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try Data(contentsOf: jsonURL)
            request.httpBody = jsonData
        } catch {
            self.showError("Failed to read JSON: \(error.localizedDescription)")
            return
        }
        
        print("🚀 Starting JSON Upload...")
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Connection Error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self?.showError("Server Error \(code).")
                    return
                }
                self?.handleServerResponse(data: data)
            }
        }
        task.resume()
    }
    
    // MARK: - Completion Logic
    func handleServerResponse(data: Data?) {
        guard let data = data else { return }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ScanResult.self, from: data)
            let resultsVC = ResultsViewController()
            resultsVC.scanResult = result
            resultsVC.scanData = scanData
            navigationController?.pushViewController(resultsVC, animated: true)
        } catch {
            print("Parsing Error: \(error)")
            showError("Could not parse server results.")
        }
    }
    
    // MARK: - UI Setup
    func setupOverlayUI() {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        statusLabel.text = "Uploading & Analyzing Energy..."
        statusLabel.font = .systemFont(ofSize: 20, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
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
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 220),
            exportButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        activityIndicator.stopAnimating()
        exportButton.isHidden = false
    }
    
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
