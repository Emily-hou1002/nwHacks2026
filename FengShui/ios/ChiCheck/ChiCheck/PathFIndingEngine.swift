import Foundation
import CoreGraphics

class PathfindingEngine {
    
    struct Point: Hashable {
        let x: Int
        let y: Int
    }
    
    let gridSize: CGFloat = 0.15
    let safetyPadding: CGFloat = 0.15
    
    func calculatePath(from jsonURL: URL) -> [CGPoint]? {
        guard let data = try? Data(contentsOf: jsonURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let objectsArray = json["objects"] as? [[String: Any]]
        else { return nil }
        
        // 1. Bounds & Parsing
        var minX: CGFloat = 0, maxX: CGFloat = 0
        var minZ: CGFloat = 0, maxZ: CGFloat = 0
        
        var obstacles: [(x: CGFloat, z: CGFloat, w: CGFloat, d: CGFloat)] = []
        var doors: [(x: CGFloat, z: CGFloat, rot: CGFloat, dist: CGFloat)] = []
        
        for obj in objectsArray {
            guard let type = obj["type"] as? String,
                  let pos = obj["position"] as? [String: Double],
                  let x = pos["x"], let z = pos["y"],
                  let dims = obj["dimensions"] as? [String: Double],
                  let w = dims["width_m"], let d = dims["length_m"]
            else { continue }
            
            let cx = CGFloat(x); let cz = CGFloat(z)
            let cw = CGFloat(w); let cd = CGFloat(d)
            // Parse Rotation (Important for the fix!)
            let rotDeg = obj["rotation_deg"] as? Double ?? 0.0
            let rotRad = CGFloat(rotDeg * .pi / 180.0)
            
            minX = min(minX, cx - cw/2); maxX = max(maxX, cx + cw/2)
            minZ = min(minZ, cz - cd/2); maxZ = max(maxZ, cz + cd/2)
            
            if type == "door" {
                doors.append((cx, cz, rotRad, sqrt(cx*cx + cz*cz)))
            } else if type != "window" {
                obstacles.append((cx, cz, cw, cd))
            }
        }
        
        // 2. Target Strategy: Approach Vector
        guard let targetDoor = doors.max(by: { $0.dist < $1.dist }) else { return nil }
        
        let startWorld = CGPoint(x: 0, y: 0)
        let doorCenter = CGPoint(x: targetDoor.x, y: targetDoor.z)
        
        // Calculate Door Normal Vector (Direction facing out)
        // Note: SceneKit Y-rotation usually maps 0 to -Z axis, but let's assume standard trig first
        let dx = sin(targetDoor.rot)
        let dz = cos(targetDoor.rot)
        
        // We need to know which side of the door is "inside".
        // Calculate two test points 0.8m away on either side of the door
        let p1 = CGPoint(x: doorCenter.x + (dx * 0.8), y: doorCenter.y + (dz * 0.8))
        let p2 = CGPoint(x: doorCenter.x - (dx * 0.8), y: doorCenter.y - (dz * 0.8))
        
        // The "Inside" point is the one closer to the room start (0,0)
        let d1 = hypot(p1.x, p1.y)
        let d2 = hypot(p2.x, p2.y)
        
        let approachPoint = (d1 < d2) ? p1 : p2
        let exitPoint     = (d1 < d2) ? p2 : p1 // The point on the OUTSIDE
        
        // 3. Grid Setup
        let gridW = Int(ceil((maxX - minX) / gridSize)) + 10
        let gridH = Int(ceil((maxZ - minZ) / gridSize)) + 10
        
        func toGrid(_ world: CGPoint) -> Point {
            let gx = Int((world.x - minX) / gridSize) + 5
            let gy = Int((world.y - minZ) / gridSize) + 5
            return Point(x: gx, y: gy)
        }
        
        func toWorld(_ p: Point) -> CGPoint {
            let wx = (CGFloat(p.x - 5) * gridSize) + minX
            let wy = (CGFloat(p.y - 5) * gridSize) + minZ
            return CGPoint(x: wx, y: wy)
        }
        
        // 4. Mark Obstacles
        var blocked = Set<Point>()
        for obs in obstacles {
            let halfW = (obs.w / 2) + safetyPadding
            let halfD = (obs.d / 2) + safetyPadding
            let pMin = toGrid(CGPoint(x: obs.x - halfW, y: obs.z - halfD))
            let pMax = toGrid(CGPoint(x: obs.x + halfW, y: obs.z + halfD))
            
            for x in pMin.x...pMax.x {
                for y in pMin.y...pMax.y {
                    blocked.insert(Point(x: x, y: y))
                }
            }
        }
        
        // 5. BFS to the APPROACH POINT (Not the door itself)
        // This ensures we navigate around furniture to get *in front* of the door first
        let startNode = toGrid(startWorld)
        let targetNode = toGrid(approachPoint)
        
        if blocked.contains(startNode) { blocked.remove(startNode) }
        if blocked.contains(targetNode) { blocked.remove(targetNode) }
        
        var queue = [startNode]
        var cameFrom = [Point: Point]()
        var visited = Set([startNode])
        var found = false
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == targetNode {
                found = true
                break
            }
            
            let neighbors = [Point(x: current.x, y: current.y+1), Point(x: current.x, y: current.y-1),
                             Point(x: current.x-1, y: current.y), Point(x: current.x+1, y: current.y)]
            
            for next in neighbors {
                if next.x >= 0 && next.x < gridW && next.y >= 0 && next.y < gridH,
                   !visited.contains(next), !blocked.contains(next) {
                    queue.append(next)
                    visited.insert(next)
                    cameFrom[next] = current
                }
            }
        }
        
        // 6. Reconstruct Path
        var path = [CGPoint]()
        
        // A. Add the Exit Point (Outside)
        path.append(exitPoint)
        
        // B. Add the Door Center
        path.append(doorCenter)
        
        // C. Add the Approach Point
        path.append(approachPoint)
        
        // D. Add the Pathfinding nodes (Approach -> Start)
        if found {
            var curr = targetNode // Start tracing back from the Approach Point
            while curr != startNode {
                // Only add grid points if they aren't super close to the approach point (smoothing)
                path.append(toWorld(curr))
                curr = cameFrom[curr]!
            }
        }
        
        path.append(startWorld)
        
        // Reverse so it goes Start -> Approach -> Door -> Exit
        return path.reversed()
    }
}
