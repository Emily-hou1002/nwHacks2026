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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Processing Scan"
        navigationItem.hidesBackButton = true
        
        setup3DBackground()
        setupOverlayUI()
        
        // START THE PATH VISUALIZATION
        generateEnergyPath()
        
        uploadFilesToServer()
    }
    
    // MARK: - Path Visualization
    func generateEnergyPath() {
        guard let url = jsonURL else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Assumes you have the updated PathfindingEngine from the previous step
            let engine = PathfindingEngine()
            if let pathPoints = engine.calculatePath(from: url) {
                DispatchQueue.main.async {
                    self.drawCloudPath(points: pathPoints)
                }
            }
        }
    }
    
    func drawCloudPath(points: [CGPoint]) {
        guard points.count > 1 else { return }
        
        let pathNode = SCNNode()
        let goldColor = UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        let particleImg = createSoftParticleImage()
        
        // Slightly higher path (0.5m) to avoid floor clipping
        let pathHeight: Float = 0.5
        
        for i in 0..<(points.count - 1) {
            let startPoint = points[i]
            let endPoint = points[i+1]
            
            let start = SCNVector3(startPoint.x, CGFloat(pathHeight), startPoint.y)
            let end = SCNVector3(endPoint.x, CGFloat(pathHeight), endPoint.y)
            let distance = distanceBetween(start, end)
            
            // 1. Particle System Setup
            let particleSystem = SCNParticleSystem()
            particleSystem.particleImage = particleImg
            particleSystem.particleColor = goldColor
            particleSystem.blendMode = .additive
            
            // INITIAL CLOUD PROPERTIES (More dispersed)
            particleSystem.particleSize = 0.15
            particleSystem.particleIntensity = 1.0
            // WIDER EMITTER: Radius 0.4m (was 0.15) for a thicker "river"
            particleSystem.emitterShape = SCNSphere(radius: 0.4)
            particleSystem.birthLocation = .volume
            
            // MOVEMENT
            let particleSpeed: CGFloat = 1.0
            particleSystem.emittingDirection = SCNVector3(0, 0, 1) // Local Forward
            particleSystem.particleVelocity = particleSpeed
            // Soft Gravity (-0.1) for a gentle settling effect
            particleSystem.acceleration = SCNVector3(0, -0.1, 0)
            
            // SPREAD (Base Value)
            particleSystem.spreadingAngle = 20 // Base spread is wider now
            
            particleSystem.particleLifeSpan = CGFloat(distance) / particleSpeed
            particleSystem.birthRate = 80 // Dense cloud
            
            // --- DYNAMIC LFO ANIMATIONS ---
            
            // Animation A: Breathing Spread (Cloud gets wider and narrower)
            let spreadAnim = CABasicAnimation(keyPath: "spreadingAngle")
            spreadAnim.fromValue = 10 // Tight beam
            spreadAnim.toValue = 20   // Wide mist
            spreadAnim.duration = 4.0 // Slow breath
            spreadAnim.autoreverses = true
            spreadAnim.repeatCount = .infinity
            spreadAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            particleSystem.addAnimation(spreadAnim, forKey: "spreadBreath")
            
            // Animation B: Size Turbulence (Particles get chunky then fine)
            let sizeAnim = CABasicAnimation(keyPath: "particleSize")
            sizeAnim.fromValue = 0.15
            sizeAnim.toValue = 0.2
            sizeAnim.duration = 2.7 // Slightly out of sync with spread for randomness
            sizeAnim.autoreverses = true
            sizeAnim.repeatCount = .infinity
            sizeAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            particleSystem.addAnimation(sizeAnim, forKey: "sizeTurbulence")
            
            // ------------------------------
            
            // 2. Attach System
            let emitterNode = SCNNode()
            emitterNode.position = start
            // Orient node to face the next point
            emitterNode.look(at: end, up: SCNVector3(0,1,0), localFront: SCNVector3(0,0,1))
            emitterNode.addParticleSystem(particleSystem)
            
            pathNode.addChildNode(emitterNode)
            
            // 3. Simple Lighting (One per node)
            let lightNode = SCNNode()
            lightNode.position = start
            let light = SCNLight()
            light.type = .omni
            light.color = goldColor
            light.intensity = 6
            light.attenuationEndDistance = 10.0
            lightNode.light = light
            pathNode.addChildNode(lightNode)
        }
        
        pathNode.renderingOrder = 100
        sceneView.scene?.rootNode.addChildNode(pathNode)
    }
    
    // Helper: Soft Particle Image
    func createSoftParticleImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: 32, height: 32)
            let path = UIBezierPath(ovalIn: rect)
            context.cgContext.addPath(path.cgPath)
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
        
        // 1. Create a Container Node for the Camera
        let cameraRig = SCNNode()
        cameraRig.position = SCNVector3(0, 0, 0)
        
        // 2. Create Camera Node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // CHANGED: Zoomed out significantly (7, 7, 7) for a wider view
        cameraNode.position = SCNVector3(0, 7, 7)
        // Angled down (-45 deg)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        
        cameraRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraRig)
        
        sceneView.pointOfView = cameraNode
        
        // 3. Rotate the RIG
        let rotateAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 25)
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
