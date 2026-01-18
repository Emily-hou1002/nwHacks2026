import Foundation
import RoomPlan
import RealityKit

class Visualizer {
    
    /// Called when the room scan has been processed
    func update(_ room: CapturedRoom) {
        // This print statement confirms the code is running successfully
        print("Visualizer update called!")
        print("Scanned room contains: \(room.walls.count) walls, \(room.windows.count) windows, and \(room.doors.count) doors.")
        
        // TODO: Add 3D drawing logic here
        // In a full app, you would take the 'room' data and generate
        // RealityKit entities (ModelEntity) to place in the ARView.
    }
}
