import UIKit
import RoomPlan

class ViewController: UIViewController {
    
    // 1. ADDED: Variable to receive user choices from the previous screen
    var config: ScanData?
    
    var roomCaptureView: RoomCaptureView!
    var currentRoom: CapturedRoom?
    var hasFinished = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Transparent Nav Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        title = "Scan Room"
        
        // Buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelScan))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(forceFinishScan))
        
        // RoomCaptureView Setup
        roomCaptureView = RoomCaptureView()
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roomCaptureView)
        
        NSLayoutConstraint.activate([
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Delegates
        roomCaptureView.delegate = self
        roomCaptureView.captureSession.delegate = self
        
        let config = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.run(configuration: config)
    }
    
    @objc func cancelScan() {
        roomCaptureView.captureSession.stop()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func forceFinishScan() {
        roomCaptureView.captureSession.stop()
        if let room = currentRoom {
            saveAndNavigate(room: room)
        }
    }
    
    func saveAndNavigate(room: CapturedRoom) {
        if hasFinished { return }
        hasFinished = true
        
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let usdzURL = docDir.appendingPathComponent("Room.usdz")
        let jsonURL = docDir.appendingPathComponent("Room.json")
        
        do {
            // 1. Save USDZ (3D Model)
            try room.export(to: usdzURL)
            
            // 2. ADDED: Prepare Data for Translator
            let calendar = Calendar.current
            // Default to 1990 if date is missing for some reason
            let birthYear = calendar.component(.year, from: config?.birthDate ?? Date(timeIntervalSince1970: 631152000))
            
            // 3. ADDED: Generate CUSTOM JSON using your Translator
            // We use the 'config' passed from the previous screen
            let jsonData = try RoomPlanTranslator.translate(
                room: room,
                roomType: config?.roomType ?? "Office",       // Default fallback
                style: config?.roomStyle ?? "Modern",         // Default fallback
                intention: config?.intention ?? "Balance",    // Default fallback
                birthYear: birthYear
            )
            
            // 4. Write Custom JSON to file
            try jsonData.write(to: jsonURL)
            
            // 5. Navigate
            DispatchQueue.main.async {
                let processingVC = ProcessingViewController()
                processingVC.usdzURL = usdzURL
                processingVC.jsonURL = jsonURL
                // Hide back button to prevent returning to scan
                processingVC.navigationItem.hidesBackButton = true
                self.navigationController?.pushViewController(processingVC, animated: true)
            }
            
        } catch {
            print("Save error: \(error)")
        }
    }
}

// Delegate Conformance
extension ViewController: RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    // UI Delegate: If user taps Apple's "Done", we intercept and use our logic
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool { return true }
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) { saveAndNavigate(room: processedResult) }
    
    // Session Delegate: Keep track of data
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) { self.currentRoom = room }
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) { self.currentRoom = room }
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) { self.currentRoom = room }
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) { self.currentRoom = room }
}
