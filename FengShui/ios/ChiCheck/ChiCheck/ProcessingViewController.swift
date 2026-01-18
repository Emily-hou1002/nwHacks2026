import UIKit
import RoomPlan

class ProcessingViewController: UIViewController {
    
    var usdzURL: URL?
    var jsonURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Exporting"
        
        let label = UILabel()
        label.text = "Processing & Exporting..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Trigger export immediately
        prepareAndShare()
    }
    
    func prepareAndShare() {
        guard let rawJsonURL = self.jsonURL, let usdzURL = self.usdzURL else { return }
        
        // Start with the USDZ model
        var itemsToShare: [URL] = [usdzURL]
        
        do {
            // 1. Decode Raw Data
            let data = try Data(contentsOf: rawJsonURL)
            let decoder = JSONDecoder()
            let room = try decoder.decode(CapturedRoom.self, from: data)
            
            // 2. Translate (Using the new Clean Translator)
            let backendData = try RoomPlanTranslator.translate(
                room: room,
                roomType: "bedroom",
                style: "modern",
                intention: "wealth",
                birthYear: 1995
            )
            
            // 3. Save Clean JSON to Temp
            let tempDir = FileManager.default.temporaryDirectory
            let cleanJsonURL = tempDir.appendingPathComponent("FengShuiPayload.json")
            try backendData.write(to: cleanJsonURL)
            
            // 4. Add to share items
            itemsToShare.append(cleanJsonURL)
            
            print("✅ JSON Cleaned & Ready")
            
        } catch {
            print("❌ Conversion Error: \(error)")
        }
        
        // 5. Present SINGLE Share Sheet
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            self.present(activityVC, animated: true)
        }
    }
}
