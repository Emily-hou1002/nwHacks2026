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
        
        // 2. Target Strategy
        guard let targetDoor = doors.max(by: { $0.dist < $1.dist }) else { return nil }
        
        let centerPoint = CGPoint(x: 0, y: 0)
        let doorCenter = CGPoint(x: targetDoor.x, y: targetDoor.z)
        
        // Calculate Approach Vector (0.8m inside the room)
        let dx = sin(targetDoor.rot)
        let dz = cos(targetDoor.rot)
        let p1 = CGPoint(x: doorCenter.x + (dx * 0.8), y: doorCenter.y + (dz * 0.8))
        let p2 = CGPoint(x: doorCenter.x - (dx * 0.8), y: doorCenter.y - (dz * 0.8))
        
        // Pick point closer to center (Inside) vs Outside
        let dist1 = hypot(p1.x, p1.y)
        let dist2 = hypot(p2.x, p2.y)
        
        let approachPoint = (dist1 < dist2) ? p1 : p2
        let exitPoint     = (dist1 < dist2) ? p2 : p1
        
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
        
        // 5. BFS (Center -> Approach)
        let startNode = toGrid(centerPoint)
        let targetNode = toGrid(approachPoint)
        
        if blocked.contains(startNode) { blocked.remove(startNode) }
        if blocked.contains(targetNode) { blocked.remove(targetNode) }
        
        var queue = [startNode]
        var cameFrom = [Point: Point]()
        var visited = Set([startNode])
        var found = false
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == targetNode { found = true; break }
            
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
        
        // 6. Reconstruct Path (Center -> Door)
        var path = [CGPoint]()
        
        if found {
            var curr = targetNode
            while curr != startNode {
                path.append(toWorld(curr))
                curr = cameFrom[curr]!
            }
        }
        path.append(centerPoint)
        
        // Currently: Approach -> ... -> Center
        // Reverse to get: Center -> ... -> Approach
        var finalPath = path.reversed() as [CGPoint]
        
        // Add final segments to get out the door
        finalPath.append(approachPoint)
        finalPath.append(doorCenter)
        finalPath.append(exitPoint)
        
        return finalPath
    }
}
