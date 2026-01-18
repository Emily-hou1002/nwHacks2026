import UIKit
import SceneKit
import QuickLook

// MARK: - Shared Models
// (Ensure these are available to this file, or keep them here if strictly local)

enum ResultOpeningType {
    case door
    case window
}

struct ResultOpeningEmitter {
    let node: SCNNode
    let width: CGFloat
    let height: CGFloat
    let type: ResultOpeningType
}

class ThreeDResultsViewController: UIViewController {
    
    // MARK: - Data Variables
    var usdzURL: URL?
    
    // MARK: - UI Elements
    private let sceneView = SCNView()
    private let closeButton = UIButton(type: .system)
    
    // MARK: - State
    private var openingEmitters: [ResultOpeningEmitter] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setup3DScene()
        setupUI()
        
        // Add particle effects after scene load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupVisualEmitters()
        }
    }
    
    // MARK: - 3D Setup
    
    func setup3DScene() {
        // 1. Setup View
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = false
        
        // ENABLE USER INTERACTION FOR RESULTS VIEW
        sceneView.allowsCameraControl = true
        sceneView.cameraControlConfiguration.autoSwitchToFreeCamera = false
        sceneView.cameraControlConfiguration.allowsTranslation = true
        
        view.insertSubview(sceneView, at: 0)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 2. Load Scene
        let scene: SCNScene?
        if let url = usdzURL {
            scene = try? SCNScene(url: url, options: nil)
        } else {
            scene = SCNScene(named: "Room.usdz")
        }
        
        guard let loadedScene = scene else { return }
        
        // 3. Process Visuals (Thick Wireframes)
        replaceWithWireframeBoxes(node: loadedScene.rootNode)
        
        // 4. Center Camera on Content
        centerCameraOnContent(scene: loadedScene)
        
        sceneView.scene = loadedScene
    }
    
    func centerCameraOnContent(scene: SCNScene) {
        // Calculate the center of the room geometry
        let (minVec, maxVec) = scene.rootNode.boundingBox
        let roomCenter = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        
        // Create a pivot node at the center of the room
        let centerNode = SCNNode()
        centerNode.position = roomCenter
        scene.rootNode.addChildNode(centerNode)
        
        // Set the camera to look at this center point
        // We position it at the "End State" of the previous animation (15, 15)
        // so the user starts with a good view.
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 15, 15)
        cameraNode.look(at: SCNVector3(0, 0, 0)) // Look at local center
        
        centerNode.addChildNode(cameraNode)
        
        // Tell SceneView to orbit around this center node
        sceneView.pointOfView = cameraNode
    }
    
    // MARK: - Geometry Processing
    
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
                
                // Detect Openings for Particles
                if let name = child.name?.lowercased() {
                    let isDoor = name.contains("door") || name.contains("opening")
                    let isWindow = name.contains("window")
                    
                    if isDoor || isWindow {
                        openingEmitters.append(
                            ResultOpeningEmitter(
                                node: child,
                                width: width,
                                height: height,
                                type: isDoor ? .door : .window
                            )
                        )
                    }
                }
                
                // Create Thick Wireframe
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
                child.geometry = nil // Hide original solid mesh
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
        
        // Y-Axis Edges
        edge(height, axis: 0, -halfW, 0, -halfL)
        edge(height, axis: 0,  halfW, 0, -halfL)
        edge(height, axis: 0, -halfW, 0,  halfL)
        edge(height, axis: 0,  halfW, 0,  halfL)
        
        // X-Axis Edges
        edge(width, axis: 1, 0,  halfH, -halfL)
        edge(width, axis: 1, 0, -halfH, -halfL)
        edge(width, axis: 1, 0,  halfH,  halfL)
        edge(width, axis: 1, 0, -halfH,  halfL)
        
        // Z-Axis Edges
        edge(length, axis: 2, -halfW,  halfH, 0)
        edge(length, axis: 2,  halfW,  halfH, 0)
        edge(length, axis: 2, -halfW, -halfH, 0)
        edge(length, axis: 2,  halfW, -halfH, 0)
        
        return container
    }
    
    // MARK: - Particle Effects
    
    func setupVisualEmitters() {
        guard !openingEmitters.isEmpty else { return }
        for opening in openingEmitters {
            createEmitter(for: opening)
        }
    }
    
    func createEmitter(for opening: ResultOpeningEmitter) {
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
        
        // Aiming: Towards center, flat trajectory
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
            
            // Random shades of gold
            ps.particleColorVariation = SCNVector4(0.1, 0.05, 0.05, 0.0)
            ps.particleSize = opening.type == .window ? 0.04 : 0.06
            
            // Constant, smooth flow
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
    
    // MARK: - UI Setup
    
    func setupUI() {
        // Add a simple Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func handleClose() {
        dismiss(animated: true, completion: nil)
    }
}
