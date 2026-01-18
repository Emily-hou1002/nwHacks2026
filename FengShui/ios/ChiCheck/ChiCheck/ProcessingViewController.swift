import UIKit
import QuickLook
import SceneKit

// MARK: - Opening Model

enum OpeningType {
    case door
    case window
}

struct OpeningEmitter {
    let node: SCNNode
    let width: CGFloat
    let height: CGFloat
    let type: OpeningType
}

// MARK: - View Controller

class ProcessingViewController: UIViewController {
    
    // MARK: - Data Variables
    var usdzURL: URL?
    var jsonURL: URL?
    var scanData: ScanData?
    
    // MARK: - UI Elements
    private let sceneView = SCNView()
    private let overlayView = UIView()
    private let statusLabel = UILabel()
    private let statusContainer = UIView()
    private let dotsLabel = UILabel()
    
    private var dotsTimer: Timer?
    private let baseStatusText = "uploading & analyzing"
    
    // MARK: - Timing Control
    private let minimumProcessingTime: TimeInterval = 10
    private var processingStartTime: Date?
    
    // MARK: - Scene State
    private let cameraRig = SCNNode()
    private let cameraNode = SCNNode()
    
    // MARK: - Opening Storage
    private var openingEmitters: [OpeningEmitter] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Processing Scan"
        navigationItem.hidesBackButton = true
        
        processingStartTime = Date()
        
        setup3DBackground()
        setupOverlayUI()
        setupDoorSparkles()
        
        // Start the upload chain
        uploadUnifiedData()
    }
    
    deinit {
        dotsTimer?.invalidate()
    }
    
    // MARK: - 3D Setup
    
    func setup3DBackground() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = false
        view.insertSubview(sceneView, at: 0)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let scene: SCNScene?
        if let url = usdzURL {
            scene = try? SCNScene(url: url, options: nil)
        } else {
            scene = SCNScene(named: "Room.usdz")
        }
        
        guard let loadedScene = scene else { return }
        
        // 1. Prepare Wireframes
        replaceWithWireframeBoxes(node: loadedScene.rootNode)
        
        // 2. Calculate Center of the Room
        let (minVec, maxVec) = loadedScene.rootNode.boundingBox
        let roomCenter = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        
        // 3. Position Rig at Center
        cameraRig.position = roomCenter
        loadedScene.rootNode.addChildNode(cameraRig)
        
        // 4. Setup Camera (Child of Rig)
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 40, 40)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        cameraRig.addChildNode(cameraNode)
        sceneView.scene = loadedScene
        
        // 5. Start Animation
        animateCameraFlyIn()
    }
    
    // MARK: - Camera Animation
    
    private func animateCameraFlyIn() {
        cameraRig.eulerAngles.y = 0
        
        // 1. ZOOM
        let zoomIn = SCNAction.move(to: SCNVector3(0, 12, 12), duration: 4.0)
        zoomIn.timingMode = .easeOut
        cameraNode.runAction(zoomIn)
        
        // 2. ORBIT + BOOST
        let constantOrbit = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 40)
        )
        
        let entryBoost = SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: 4.0)
        entryBoost.timingMode = .easeOut
        
        cameraRig.runAction(constantOrbit)
        cameraRig.runAction(entryBoost)
    }
    
    // MARK: - Scene Traversal
    
    private func replaceWithWireframeBoxes(node: SCNNode) {
        for child in node.childNodes {
            
            if child.name == "WireframeBox" { continue }
            
            if let name = child.name?.lowercased(), name.contains("floor") {
                child.isHidden = true
                continue
            }
            
            if let geo = child.geometry {
                let (minVec, maxVec) = child.boundingBox
                let width = CGFloat(maxVec.x - minVec.x)
                let height = CGFloat(maxVec.y - minVec.y)
                let length = CGFloat(maxVec.z - minVec.z)
                
                if let name = child.name?.lowercased() {
                    let isDoor = name.contains("door") || name.contains("opening")
                    let isWindow = name.contains("window")
                    
                    if isDoor || isWindow {
                        openingEmitters.append(
                            OpeningEmitter(
                                node: child,
                                width: width,
                                height: height,
                                type: isDoor ? .door : .window
                            )
                        )
                    }
                }
                
                let wireframeNode = createThickWireframe(
                    width: width,
                    height: height,
                    length: length,
                    thickness: 0.008
                )
                wireframeNode.name = "WireframeBox"
                wireframeNode.position = SCNVector3(
                    (minVec.x + maxVec.x) / 2,
                    (minVec.y + maxVec.y) / 2,
                    (minVec.z + maxVec.z) / 2
                )
                
                child.addChildNode(wireframeNode)
                child.geometry = nil
            }
            
            replaceWithWireframeBoxes(node: child)
        }
    }
    
    private func createThickWireframe(width: CGFloat, height: CGFloat, length: CGFloat, thickness: CGFloat) -> SCNNode {
        let container = SCNNode()
        let halfW = width / 2
        let halfH = height / 2
        let halfL = length / 2
        
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = UIColor.white
        
        func edge(_ h: CGFloat, axis: Int, _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
            let cyl = SCNCylinder(radius: thickness, height: h)
            cyl.materials = [mat]
            let n = SCNNode(geometry: cyl)
            if axis == 1 { n.eulerAngles.z = .pi / 2 }
            if axis == 2 { n.eulerAngles.x = .pi / 2 }
            n.position = SCNVector3(x, y, z)
            container.addChildNode(n)
        }
        
        edge(height, axis: 0, -halfW, 0, -halfL)
        edge(height, axis: 0,  halfW, 0, -halfL)
        edge(height, axis: 0, -halfW, 0,  halfL)
        edge(height, axis: 0,  halfW, 0,  halfL)
        
        edge(width, axis: 1, 0,  halfH, -halfL)
        edge(width, axis: 1, 0, -halfH, -halfL)
        edge(width, axis: 1, 0,  halfH,  halfL)
        edge(width, axis: 1, 0, -halfH,  halfL)
        
        edge(length, axis: 2, -halfW,  halfH, 0)
        edge(length, axis: 2,  halfW,  halfH, 0)
        edge(length, axis: 2, -halfW, -halfH, 0)
        edge(length, axis: 2,  halfW, -halfH, 0)
        
        return container
    }
    
    // MARK: - Emitters
    
    func setupDoorSparkles() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupVisualEmitters()
        }
    }
    
    func setupVisualEmitters() {
        guard !openingEmitters.isEmpty else { return }
        for opening in openingEmitters {
            createEmitter(for: opening)
        }
    }
    
    func createEmitter(for opening: OpeningEmitter) {
        guard let root = sceneView.scene?.rootNode else { return }
        
        let crossImage = createCrossImage()
        let slices = opening.type == .window ? 5 : 6
        
        let widthPerSlice = opening.width / CGFloat(slices)
        let startX = -(opening.width / 2) + (widthPerSlice / 2)
        
        let (minVec, maxVec) = opening.node.boundingBox
        let centerY = (minVec.y + maxVec.y) / 2
        
        let emitterNode = SCNNode()
        emitterNode.position = opening.node.worldPosition
        emitterNode.position.y += Float(centerY)
        
        let aimTarget = SCNVector3(0, emitterNode.position.y, 0)
        
        emitterNode.look(at: aimTarget,
                         up: root.worldUp,
                         localFront: SCNVector3(0, 0, 1))
        
        root.addChildNode(emitterNode)
        
        let goldColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        
        for i in 0..<slices {
            let sliceNode = SCNNode()
            sliceNode.position = SCNVector3(startX + CGFloat(i) * widthPerSlice, 0, 0)
            
            let ps = SCNParticleSystem()
            ps.particleImage = crossImage
            ps.particleColor = goldColor
            ps.blendMode = .additive
            
            ps.particleColorVariation = SCNVector4(0.1, 0.05, 0.05, 0.0)
            
            ps.particleSize = opening.type == .window ? 0.04 : 0.06
            ps.birthRate = opening.type == .window ? 18 : 20
            
            ps.particleLifeSpan = 2.5
            ps.particleLifeSpanVariation = 1.0
            
            ps.particleVelocity = 1.0
            ps.particleVelocityVariation = 0.5
            ps.spreadingAngle = 8
            
            ps.emitterShape = SCNBox(
                width: widthPerSlice,
                height: opening.height,
                length: 0,
                chamferRadius: 0
            )
            
            ps.emittingDirection = SCNVector3(0, 0, 1)
            ps.acceleration = SCNVector3(0, 0, 0.1)
            
            sliceNode.addParticleSystem(ps)
            emitterNode.addChildNode(sliceNode)
        }
    }
    
    func createCrossImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64)).image { ctx in
            let c = ctx.cgContext
            c.setShadow(offset: .zero, blur: 4, color: UIColor.white.cgColor)
            c.setFillColor(UIColor.white.cgColor)
            c.fill(CGRect(x: 28, y: 8, width: 8, height: 48))
            c.fill(CGRect(x: 8, y: 28, width: 48, height: 8))
        }
    }
    
    // MARK: - Networking Chain
    
    // MARK: - Debug Helper
        func exportDebugJSON(data: Data) {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // Create a unique filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "transposed_room_\(timestamp).json"
            
            let fileURL = docDir.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                print("💾 [Debug] Saved local JSON copy to: \(fileURL.path)")
            } catch {
                print("❌ [Debug] Failed to save local JSON: \(error)")
            }
        }
    
    
    // MARK: - Unified Upload (Matches your JS Example)
    func uploadUnifiedData() {
            // 1. Validate URLs
            var targetJSON = jsonURL
            var targetUSDZ = usdzURL
            
            // Simulator Fallbacks
            if targetJSON == nil { targetJSON = Bundle.main.url(forResource: "Room", withExtension: "json") }
            if targetUSDZ == nil { targetUSDZ = Bundle.main.url(forResource: "Room", withExtension: "usdz") }
            
            guard let finalJSON = targetJSON, let finalUSDZ = targetUSDZ,
                  let serverURL = URL(string: "https://runnier-shaniqua-yeasty.ngrok-free.dev/analyze-room-with-model")
            else {
                print("❌ Missing Files or Invalid URL")
                return
            }
            
            DispatchQueue.main.async { self.statusLabel.text = "Uploading scan data..." }

            // 2. Load and Validate Data
            guard let jsonData = try? Data(contentsOf: finalJSON),
                  let requestObj = try? JSONDecoder().decode(FSRequest.self, from: jsonData) else {
                print("❌ Failed to decode JSON file")
                return
            }
            
            guard let fileData = try? Data(contentsOf: finalUSDZ) else {
                print("❌ Failed to read USDZ file data")
                return
            }
            
            // --- DEBUG: Verify File Integrity ---
            print("📦 USDZ Size: \(fileData.count) bytes")
            if fileData.count > 4 {
                // Check for Zip Magic Bytes (PK..) -> 0x50, 0x4B
                if fileData[0] == 0x50 && fileData[1] == 0x4B {
                    print("✅ File Header: Valid ZIP/USDZ signature found.")
                } else {
                    print("⚠️ WARNING: File does not look like a valid ZIP/USDZ! (First bytes: \(fileData[0]), \(fileData[1]))")
                }
            }
            // ------------------------------------
            saveDebugJSON(request: requestObj)
            // 3. Prepare Request
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // 4. Build Body safely
            let httpBody = NSMutableData()
            let encoder = JSONEncoder()
            
            func appendText(name: String, value: String) {
                httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
                httpBody.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
                httpBody.append("\(value)\r\n".data(using: .utf8)!)
            }
            
            // A. Append JSON Fields
            if let data = try? encoder.encode(requestObj.room_metadata), let str = String(data: data, encoding: .utf8) {
                appendText(name: "room_metadata", value: str)
            }
            if let data = try? encoder.encode(requestObj.room_dimensions), let str = String(data: data, encoding: .utf8) {
                appendText(name: "room_dimensions", value: str)
            }
            if let data = try? encoder.encode(requestObj.objects), let str = String(data: data, encoding: .utf8) {
                appendText(name: "objects", value: str)
            }
            
            // B. Append File (Binary)
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"model_file\"; filename=\"Room.usdz\"\r\n".data(using: .utf8)!)
            httpBody.append("Content-Type: application/zip\r\n\r\n".data(using: .utf8)!) // Changed to generic zip to be safe
            httpBody.append(fileData)
            httpBody.append("\r\n".data(using: .utf8)!)
            
            // C. Close Boundary
            httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = httpBody as Data
            
            // 5. Send
            print("🚀 Sending Unified Request (\(httpBody.length) bytes)...")
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error { print("❌ Network Error: \(error)"); return }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        // Print server error message if available
                        if let data = data, let errStr = String(data: data, encoding: .utf8) {
                            print("❌ Server Error Message: \(errStr)")
                        }
                    }
                }
                
                guard let data = data else { return }
                
                // Decode Result
                do {
                    let result = try JSONDecoder().decode(ScanResult.self, from: data)
                    DispatchQueue.main.async {
                        self.handleResultWithMinimumDelay(result)
                    }
                } catch {
                    print("❌ Decode Error: \(error)")
                    print("📄 Raw Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                }
            }.resume()
        }
    
    
    func saveDebugJSON(request: FSRequest) {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // Generate filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "debug_payload_\(timestamp).json"
            let fileURL = docDir.appendingPathComponent(filename)
            
            // Encode and Write
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            do {
                let data = try encoder.encode(request)
                try data.write(to: fileURL)
                print("💾 [Debug] JSON saved to: \(fileURL.path)")
            } catch {
                print("❌ [Debug] Failed to save JSON: \(error)")
            }
        }
        // MARK: - Multipart Helper
        func createMultipartBody(data: Data, boundary: String, filename: String, mimeType: String) -> Data {
            let body = NSMutableData()
            let lineBreak = "\r\n"
            
            // 1. Boundary + Content Disposition
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
            
            // 2. File Data
            body.append(data)
            body.append(lineBreak.data(using: .utf8)!)
            
            // 3. Close Boundary
            body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
            
            return body as Data
        }
    
    private func handleResultWithMinimumDelay(_ result: ScanResult) {
        let elapsed = Date().timeIntervalSince(processingStartTime ?? Date())
        let remaining = max(0, minimumProcessingTime - elapsed)
        
        // Update UI to show we are analyzing/finishing
        statusLabel.text = "Finalizing analysis..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            let vc = ResultsViewController()
            vc.scanResult = result
            vc.scanData = self.scanData
            vc.usdzURL = self.usdzURL
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Overlay UI
    
    func setupOverlayUI() {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.backgroundColor = .black
        statusContainer.layer.cornerRadius = 14
        statusContainer.layer.borderWidth = 1
        statusContainer.layer.borderColor = UIColor.white.cgColor
        view.addSubview(statusContainer)
        
        statusLabel.text = baseStatusText
        statusLabel.textColor = .white
        statusLabel.font = .monospacedSystemFont(ofSize: 16, weight: .semibold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dotsLabel.text = "..."
        dotsLabel.textColor = .white
        dotsLabel.font = statusLabel.font
        dotsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusContainer.addSubview(statusLabel)
        statusContainer.addSubview(dotsLabel)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            statusContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statusContainer.heightAnchor.constraint(equalToConstant: 44),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 20),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            
            dotsLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            dotsLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -20),
            dotsLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor)
        ])
        
        startDotsAnimation()
    }
    
    func startDotsAnimation() {
        var count = 1
        dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let attr = NSMutableAttributedString(string: "...")
            for i in 0..<3 {
                let alpha: CGFloat = i < count ? 1 : 0
                attr.addAttribute(
                    .foregroundColor,
                    value: UIColor.white.withAlphaComponent(alpha),
                    range: NSRange(location: i, length: 1)
                )
            }
            self.dotsLabel.attributedText = attr
            count = count == 3 ? 1 : count + 1
        }
    }
}
