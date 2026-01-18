# .usdz File Upload Feature

## Overview

The backend now supports uploading `.usdz` 3D model files alongside room analysis data. This allows the frontend to send both the 3D model and the structured room data for analysis.

## Endpoint

**POST** `/analyze-room-with-model`

## Request Format

This endpoint uses `multipart/form-data` to accept:
1. A `.usdz` file (3D model)
2. JSON strings for room metadata, dimensions, and objects

### Form Fields

- `model_file`: The `.usdz` file (required)
- `room_metadata`: JSON string of room metadata (required)
- `room_dimensions`: JSON string of room dimensions (required)
- `objects`: JSON string of objects array (required)

### Example: JavaScript/TypeScript (Frontend)

```javascript
async function analyzeRoomWithModel(usdzFile, roomData) {
  const formData = new FormData();
  
  // Add the .usdz file
  formData.append('model_file', usdzFile);
  
  // Add JSON data as strings
  formData.append('room_metadata', JSON.stringify(roomData.room_metadata));
  formData.append('room_dimensions', JSON.stringify(roomData.room_dimensions));
  formData.append('objects', JSON.stringify(roomData.objects));
  
  const response = await fetch('http://localhost:8000/analyze-room-with-model', {
    method: 'POST',
    body: formData
  });
  
  return await response.json();
}

// Usage example
const fileInput = document.querySelector('input[type="file"]');
const usdzFile = fileInput.files[0];

const roomData = {
  room_metadata: {
    room_type: "bedroom",
    feng_shui_intention: "health",
    room_style: "minimalist"
  },
  room_dimensions: {
    length_m: 4.5,
    width_m: 3.5,
    height_m: 2.7
  },
  objects: [
    {
      id: "bed_1",
      type: "bed",
      position: { x: 2.25, y: 1.0 },
      rotation_deg: 90,
      dimensions: { length_m: 2.0, width_m: 1.5, height_m: 0.5 }
    }
    // ... more objects
  ]
};

const result = await analyzeRoomWithModel(usdzFile, roomData);
```

### Example: Swift (iOS)

```swift
func analyzeRoomWithModel(usdzURL: URL, roomData: RoomData) async throws -> AnalyzeRoomResponse {
    let url = URL(string: "http://localhost:8000/analyze-room-with-model")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add .usdz file
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"model_file\"; filename=\"room.usdz\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: model/vnd.usdz+zip\r\n\r\n".data(using: .utf8)!)
    body.append(try Data(contentsOf: usdzURL))
    body.append("\r\n".data(using: .utf8)!)
    
    // Add room_metadata
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"room_metadata\"\r\n\r\n".data(using: .utf8)!)
    body.append(try JSONEncoder().encode(roomData.roomMetadata))
    body.append("\r\n".data(using: .utf8)!)
    
    // Add room_dimensions
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"room_dimensions\"\r\n\r\n".data(using: .utf8)!)
    body.append(try JSONEncoder().encode(roomData.roomDimensions))
    body.append("\r\n".data(using: .utf8)!)
    
    // Add objects
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"objects\"\r\n\r\n".data(using: .utf8)!)
    body.append(try JSONEncoder().encode(roomData.objects))
    body.append("\r\n".data(using: .utf8)!)
    
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(AnalyzeRoomResponse.self, from: data)
}
```

## Response Format

The response is identical to `/analyze-room`:

```json
{
  "feng_shui_score": 72,
  "bagua_analysis": [...],
  "suggestions": [...],
  "ui_hints": {
    "highlight_objects": [...],
    "recommended_zones": [...]
  }
}
```

## File Storage

- Uploaded `.usdz` files are stored in `FengShui/backend/uploads/`
- Files are renamed with UUIDs to prevent conflicts
- Files are stored permanently (no automatic cleanup)
- Maximum file size: 50MB

## Validation

- File type must be `.usdz`
- File size must be ≤ 50MB
- JSON fields must be valid JSON strings
- JSON data must match `AnalyzeRoomRequest` schema

## Error Handling

- **400 Bad Request**: Invalid file type, file too large, or invalid JSON
- **500 Internal Server Error**: Failed to store file

## Future Enhancements

- Parse `.usdz` files to extract object positions automatically
- Use `.usdz` files for AI visual analysis (Gemini Vision API)
- Automatic cleanup of old uploaded files
- File retrieval endpoint to download stored models

## Notes

- The current implementation uses the JSON data for analysis (same as `/analyze-room`)
- The `.usdz` file is stored but not yet parsed/used in analysis
- This endpoint is designed for future enhancements where the 3D model can be used for visual AI analysis
