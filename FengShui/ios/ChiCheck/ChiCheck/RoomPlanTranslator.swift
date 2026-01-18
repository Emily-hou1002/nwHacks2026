import Foundation
import RoomPlan
import simd

// MARK: - 1. Strict API Models
struct FSRequest: Encodable {
    let room_metadata: FSRoomMetadata
    let room_dimensions: FSRoomDimensions
    let objects: [FSRoomObject]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(room_metadata, forKey: .room_metadata)
        try container.encode(room_dimensions, forKey: .room_dimensions)
        try container.encode(objects, forKey: .objects)
    }
    enum CodingKeys: String, CodingKey { case room_metadata, room_dimensions, objects }
}

struct FSRoomMetadata: Encodable {
    let room_type: String
    let north_direction_deg: Double
    let room_style: String
    let feng_shui_intention: String
    let birth_year: Int
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(room_type, forKey: .room_type)
        try container.encode(north_direction_deg, forKey: .north_direction_deg)
        try container.encode(room_style, forKey: .room_style)
        try container.encode(feng_shui_intention, forKey: .feng_shui_intention)
        try container.encode(birth_year, forKey: .birth_year)
    }
    enum CodingKeys: String, CodingKey { case room_type, north_direction_deg, room_style, feng_shui_intention, birth_year }
}

struct FSRoomDimensions: Encodable {
    let length_m: Double
    let width_m: Double
    let height_m: Double
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(length_m, forKey: .length_m)
        try container.encode(width_m, forKey: .width_m)
        try container.encode(height_m, forKey: .height_m)
    }
    enum CodingKeys: String, CodingKey { case length_m, width_m, height_m }
}

struct FSRoomObject: Encodable {
    let id: String
    let type: String
    let position: FSPosition
    let rotation_deg: Double
    let dimensions: FSObjectDimensions
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(position, forKey: .position)
        try container.encode(rotation_deg, forKey: .rotation_deg)
        try container.encode(dimensions, forKey: .dimensions)
    }
    enum CodingKeys: String, CodingKey { case id, type, position, rotation_deg, dimensions }
}

struct FSPosition: Encodable {
    let x: Double
    let y: Double
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    enum CodingKeys: String, CodingKey { case x, y }
}

struct FSObjectDimensions: Encodable {
    let length_m: Double
    let width_m: Double
    let height_m: Double
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(length_m, forKey: .length_m)
        try container.encode(width_m, forKey: .width_m)
        try container.encode(height_m, forKey: .height_m)
    }
    enum CodingKeys: String, CodingKey { case length_m, width_m, height_m }
}

// MARK: - 2. Translator Logic

class RoomPlanTranslator {
    
    static func translate(
        room: CapturedRoom,
        roomType: String,
        style: String,
        intention: String,
        birthYear: Int
    ) throws -> Data {
        
        // 1. Lowercase and Sanitize Inputs
        let cleanType = roomType.lowercased().replacingOccurrences(of: " ", with: "_")
        let cleanStyle = style.lowercased()
        
        // Map Intention
        let rawIntention = intention.lowercased()
        let cleanIntention: String
        switch rawIntention {
        case "love": cleanIntention = "relationships"
        case "balance": cleanIntention = "health"
        case "wealth", "fame", "health", "creativity", "knowledge", "career", "helpful_people":
            cleanIntention = rawIntention
        default:
            cleanIntention = "health"
        }
        
        // 2. Metadata
        let metadata = FSRoomMetadata(
            room_type: cleanType,
            north_direction_deg: 0.0,
            room_style: cleanStyle,
            feng_shui_intention: cleanIntention,
            birth_year: birthYear
        )
        
        // 3. Room Dimensions (Clamped to avoid 0.0 errors)
        let bounds = calculateRoomBounds(room)
        let roomDims = FSRoomDimensions(
            length_m: clamp(bounds.depth),
            width_m: clamp(bounds.width),
            height_m: 2.7
        )
        
        // 4. Objects
        var apiObjects: [FSRoomObject] = []
        
        for object in room.objects {
            apiObjects.append(convert(object: object))
        }
        
        for door in room.doors {
            apiObjects.append(convert(surface: door, type: "door"))
        }
        
        for window in room.windows {
            apiObjects.append(convert(surface: window, type: "window"))
        }
        
        // 5. Payload Construction
        let requestPayload = FSRequest(
            room_metadata: metadata,
            room_dimensions: roomDims,
            objects: apiObjects
        )
        
        // 6. Encode
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Return standard JSON (one set of curly braces by default)
        return try encoder.encode(requestPayload)
    }
    
    // MARK: - Helpers
    
    private static func convert(object: CapturedRoom.Object) -> FSRoomObject {
        return createObject(
            id: object.identifier.uuidString,
            type: mapCategory(object.category).lowercased(), // Ensure type is lowercase
            transform: object.transform,
            dims: object.dimensions
        )
    }
    
    private static func convert(surface: CapturedRoom.Surface, type: String) -> FSRoomObject {
        return createObject(
            id: surface.identifier.uuidString,
            type: type.lowercased(), // Ensure type is lowercase
            transform: surface.transform,
            dims: surface.dimensions
        )
    }
    
    private static func createObject(id: String, type: String, transform: simd_float4x4, dims: simd_float3) -> FSRoomObject {
        let pos = FSPosition(
            x: snap(Float(transform.columns.3.x)),
            y: snap(Float(transform.columns.3.z))
        )
        
        // CLAMP DIMENSIONS HERE: Enforce min 0.1m thickness/width/height
        let objDims = FSObjectDimensions(
            length_m: clamp(Float(dims.z)),
            width_m:  clamp(Float(dims.x)),
            height_m: clamp(Float(dims.y))
        )
        
        return FSRoomObject(
            id: id,
            type: type,
            position: pos,
            rotation_deg: snap(extractRotation(matrix: transform)),
            dimensions: objDims
        )
    }
    
    // MARK: - Math Helpers
    
    // Rounds to 2 decimal places standard
    private static func snap(_ value: Float) -> Double {
        let rounded = (value * 100).rounded() / 100
        return Double(rounded)
    }
    
    // Rounds AND enforces minimum value of 0.1
    // This fixes "infinite thinness" backend errors
    private static func clamp(_ value: Float) -> Double {
        let rounded = (value * 100).rounded() / 100
        return max(Double(rounded), 0.1)
    }
    
    private static func extractRotation(matrix: simd_float4x4) -> Float {
        let z = matrix.columns.2.z
        let x = matrix.columns.2.x
        let angleRad = atan2(x, z)
        var angleDeg = angleRad * (180.0 / .pi)
        if angleDeg < 0 { angleDeg += 360 }
        return angleDeg
    }
    
    private static func calculateRoomBounds(_ room: CapturedRoom) -> (width: Float, depth: Float) {
        var minX: Float = 0, maxX: Float = 0
        var minZ: Float = 0, maxZ: Float = 0
        
        if let first = room.walls.first {
            minX = first.transform.columns.3.x; maxX = minX
            minZ = first.transform.columns.3.z; maxZ = minZ
        }
        
        for item in room.walls {
            let x = item.transform.columns.3.x
            let z = item.transform.columns.3.z
            let halfW = item.dimensions.x / 2
            let halfD = item.dimensions.z / 2
            
            minX = min(minX, x - halfW); maxX = max(maxX, x + halfW)
            minZ = min(minZ, z - halfD); maxZ = max(maxZ, z + halfD)
        }
        return (width: maxX - minX, depth: maxZ - minZ)
    }
    
    private static func mapCategory(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .storage: return "storage"
        case .refrigerator: return "refrigerator"
        case .stove: return "stove"
        case .bed: return "bed"
        case .sink: return "sink"
        case .washerDryer: return "washer_dryer"
        case .toilet: return "toilet"
        case .bathtub: return "bathtub"
        case .oven: return "oven"
        case .dishwasher: return "dishwasher"
        case .table: return "table"
        case .sofa: return "sofa"
        case .chair: return "chair"
        case .fireplace: return "fireplace"
        case .television: return "television"
        case .stairs: return "stairs"
        @unknown default: return "furniture"
        }
    }
}
