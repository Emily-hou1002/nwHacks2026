import UIKit
import RoomPlan

class ViewController: UIViewController {
    
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
            // 1. Save Raw Files Locally
            try room.export(to: usdzURL)
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(room)
            try jsonData.write(to: jsonURL)
            
            // 2. Navigate immediately (NO SHARE SHEET HERE)
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
