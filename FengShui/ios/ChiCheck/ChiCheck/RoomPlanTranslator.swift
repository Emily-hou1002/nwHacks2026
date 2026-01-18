import Foundation
import RoomPlan
import simd

// MARK: - 1. Strict API Models
// We prefix with 'FS' (Feng Shui) to avoid conflicts with other models.

struct FSRequest: Encodable {
    let room_metadata: FSRoomMetadata
    let room_dimensions: FSRoomDimensions
    let objects: [FSRoomObject]
    
    // Explicit encoding ensures "room_metadata" always comes before "objects"
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
    
    // STRICT ORDER: id -> type -> position -> rotation -> dimensions
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
    
    // STRICT ORDER: length -> width -> height
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
        
        // --- 1. Map Metadata ---
        let metadata = FSRoomMetadata(
            room_type: roomType,
            north_direction_deg: 0.0, // Default to 0 until Compass logic is added
            room_style: style,
            feng_shui_intention: intention,
            birth_year: birthYear
        )
        
        // --- 2. Map Room Dimensions ---
        let bounds = calculateRoomBounds(room)
        let roomDims = FSRoomDimensions(
            length_m: snap(bounds.depth),
            width_m: snap(bounds.width),
            height_m: 2.7 // Standard ceiling height assumption
        )
        
        // --- 3. Map Objects ---
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
        
        // --- 4. Build Payload ---
        let requestPayload = FSRequest(
            room_metadata: metadata,
            room_dimensions: roomDims,
            objects: apiObjects
        )
        
        // --- 5. Encode ---
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        // DO NOT USE .sortedKeys - it breaks our custom order
        
        return try encoder.encode(requestPayload)
    }
    
    // MARK: - Helper Functions
    
    private static func convert(object: CapturedRoom.Object) -> FSRoomObject {
        return createObject(
            id: object.identifier.uuidString,
            type: mapCategory(object.category),
            transform: object.transform,
            dims: object.dimensions
        )
    }
    
    private static func convert(surface: CapturedRoom.Surface, type: String) -> FSRoomObject {
        return createObject(
            id: surface.identifier.uuidString,
            type: type,
            transform: surface.transform,
            dims: surface.dimensions
        )
    }
    
    private static func createObject(id: String, type: String, transform: simd_float4x4, dims: simd_float3) -> FSRoomObject {
        // Create Position
        let pos = FSPosition(
            x: snap(Float(transform.columns.3.x)),
            y: snap(Float(transform.columns.3.z))
        )
        
        // Create Dimensions
        let objDims = FSObjectDimensions(
            length_m: snap(Float(dims.z)), // Z maps to length/depth
            width_m:  snap(Float(dims.x)),
            height_m: snap(Float(dims.y))
        )
        
        return FSRoomObject(
            id: id,
            type: type,
            position: pos,
            rotation_deg: snap(extractRotation(matrix: transform)),
            dimensions: objDims
        )
    }
    
    // MARK: - Math & Snap Helpers
    
    // "Snap" function: rounds to exactly 2 decimal places to keep JSON clean
    private static func snap(_ value: Float) -> Double {
        let stringVal = String(format: "%.2f", value)
        return Double(stringVal) ?? 0.0
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
        
        let allItems = room.walls
        if let first = allItems.first {
            minX = first.transform.columns.3.x; maxX = minX
            minZ = first.transform.columns.3.z; maxZ = minZ
        }
        
        for item in allItems {
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
