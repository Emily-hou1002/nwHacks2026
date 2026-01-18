# Swift Frontend Code Review & Fixes

## Current Code Analysis

Your Swift code in `uploadUnifiedData()` looks **mostly correct**! It's:
- ✅ Creating multipart/form-data correctly
- ✅ Appending file first
- ✅ Stringifying JSON fields
- ✅ Closing boundary properly

## Potential Issues & Fixes

### Issue 1: Silent Failure in `appendJSONField`

The `appendJSONField` function uses `guard let` and returns silently if encoding fails. This could cause validation errors.

**Current Code:**
```swift
func appendJSONField(name: String, data: Codable) {
    guard let jsonBytes = try? encoder.encode(data),
          let jsonString = String(data: jsonBytes, encoding: .utf8) else { return }
    // ...
}
```

**Fixed Code:**
```swift
func appendJSONField(name: String, data: Codable) throws {
    // 1. Encode struct to Data
    let jsonBytes = try encoder.encode(data)
    
    // 2. Convert Data to String (JSON.stringify)
    guard let jsonString = String(data: jsonBytes, encoding: .utf8) else {
        throw NSError(domain: "EncodingError", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to convert \(name) to UTF-8 string"])
    }
    
    // 3. Append to Body
    httpBody.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
    httpBody.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
    httpBody.append("\(jsonString)\(lineBreak)".data(using: .utf8)!)
}
```

Then update the calls:
```swift
do {
    try appendJSONField(name: "room_metadata", data: requestObj.room_metadata)
    try appendJSONField(name: "room_dimensions", data: requestObj.room_dimensions)
    try appendJSONField(name: "objects", data: requestObj.objects)
} catch {
    print("❌ JSON Encoding Error: \(error)")
    return
}
```

### Issue 2: Verify JSON Encoding Matches Backend Expectations

Make sure your `FSRequest` struct matches the backend's `AnalyzeRoomRequest`:

```swift
struct FSRequest: Codable {
    let room_metadata: RoomMetadata
    let room_dimensions: RoomDimensions
    let objects: [RoomObject]
}

struct RoomMetadata: Codable {
    let birth_year: Int?
    let north_direction_deg: Float?
    let room_type: String?
    let room_style: String?
    let feng_shui_intention: String?
}

struct RoomDimensions: Codable {
    let length_m: Float
    let width_m: Float
    let height_m: Float
}

struct RoomObject: Codable {
    let id: String
    let rotation_deg: Float
    let position: Position
    let type: String
    let dimensions: Dimensions
}

struct Position: Codable {
    let x: Float
    let y: Float
}

struct Dimensions: Codable {
    let length_m: Float
    let width_m: Float
    let height_m: Float
}
```

### Issue 3: Add Debugging

Add more logging to see what's being sent:

```swift
// After building httpBody, before sending:
print("📦 Request Details:")
print("  - File size: \(fileData.count) bytes")
print("  - Boundary: \(boundary)")
print("  - Total body size: \(httpBody.length) bytes")

// Log JSON field sizes
if let metadataData = try? encoder.encode(requestObj.room_metadata),
   let metadataStr = String(data: metadataData, encoding: .utf8) {
    print("  - room_metadata: \(metadataStr.count) chars")
    print("  - room_metadata preview: \(String(metadataStr.prefix(100)))...")
}
```

### Issue 4: Verify File is Valid

Add validation before sending:

```swift
// Before building request, validate file
if fileData.isEmpty {
    print("❌ ERROR: USDZ file is empty")
    DispatchQueue.main.async {
        self.statusLabel.text = "Error: Invalid file"
    }
    return
}

// Check if it's a valid zip (optional but helpful)
import Compression
// Or just check file size is reasonable
if fileData.count < 100 {
    print("⚠️ WARNING: File seems too small (\(fileData.count) bytes)")
}
```

## Complete Fixed `appendJSONField` Function

```swift
func appendJSONField(name: String, data: Codable) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [] // No pretty printing for form data
    
    // 1. Encode struct to Data
    let jsonBytes = try encoder.encode(data)
    
    // 2. Convert Data to String (JSON.stringify)
    guard let jsonString = String(data: jsonBytes, encoding: .utf8) else {
        throw NSError(domain: "EncodingError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "Failed to convert \(name) to UTF-8"])
    }
    
    // Debug: Log first 100 chars
    print("📝 \(name): \(jsonString.prefix(100))...")
    
    // 3. Append to Body
    httpBody.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
    httpBody.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
    httpBody.append("\(jsonString)\(lineBreak)".data(using: .utf8)!)
}
```

## Testing Checklist

1. ✅ Verify file is not empty
2. ✅ Verify JSON encoding succeeds for all fields
3. ✅ Check that boundary format matches exactly
4. ✅ Verify Content-Type header is set correctly
5. ✅ Check server logs for actual received data
6. ✅ Compare with Python test script output

## Quick Test

Run the Python test script to see what a working request looks like:
```bash
cd FengShui/backend/app
python test_upload.py
```

Then compare the output with your Swift app's logs to see if there are differences.
