/**
 * Frontend example: How to send the request correctly
 * 
 * This shows how the frontend should format the request using the data from sample.json
 */

// Example 1: If you have the file locally
async function analyzeRoomWithLocalFile(usdzFile, roomData) {
  const formData = new FormData();
  
  // Add the .usdz file (actual file object, not URL!)
  formData.append('model_file', usdzFile, 'Room.usdz');
  
  // Add JSON data as STRINGS (must stringify!)
  formData.append('room_metadata', JSON.stringify(roomData.room_metadata));
  formData.append('room_dimensions', JSON.stringify(roomData.room_dimensions));
  formData.append('objects', JSON.stringify(roomData.objects));
  
  const response = await fetch('http://localhost:8000/analyze-room-with-model', {
    method: 'POST',
    body: formData  // Don't set Content-Type - browser does it automatically!
  });
  
  const fileId = response.headers.get('X-File-Id');
  const result = await response.json();
  
  return { result, fileId };
}

// Example 2: If you only have a URL, download first then upload
async function analyzeRoomWithUrl(modelFileUrl, roomData) {
  // Step 1: Download the file from URL
  const fileResponse = await fetch(modelFileUrl);
  if (!fileResponse.ok) {
    throw new Error(`Failed to download file: ${fileResponse.statusText}`);
  }
  
  const blob = await fileResponse.blob();
  const file = new File([blob], 'Room.usdz', { type: 'model/vnd.usdz+zip' });
  
  // Step 2: Upload to backend (same as Example 1)
  return await analyzeRoomWithLocalFile(file, roomData);
}

// Example 3: Using the sample.json data structure
async function testWithSampleData() {
  // Load your sample.json (or use the data directly)
  const roomData = {
    room_metadata: {
      birth_year: 2019,
      north_direction_deg: 0,
      room_type: "office",
      room_style: "bohemian",
      feng_shui_intention: "knowledge"
    },
    room_dimensions: {
      length_m: 10.010000228881836,
      width_m: 8.680000305175781,
      height_m: 2.7
    },
    objects: [
      {
        id: "B820699F-1E92-4079-98CE-030ED055D336",
        rotation_deg: 15.680000305175781,
        position: { x: 2.25, y: -2 },
        type: "chair",
        dimensions: {
          width_m: 0.550000011920929,
          height_m: 0.75,
          length_m: 0.5600000023841858
        }
      }
      // ... more objects from sample.json
    ]
  };
  
  // Get file from file input or URL
  const fileInput = document.querySelector('input[type="file"]');
  const usdzFile = fileInput?.files[0];
  
  if (!usdzFile) {
    // If no file input, try downloading from URL
    return await analyzeRoomWithUrl('http://localhost/Room.usdz', roomData);
  }
  
  return await analyzeRoomWithLocalFile(usdzFile, roomData);
}

// Usage:
// testWithSampleData().then(({ result, fileId }) => {
//   console.log('Score:', result.feng_shui_score);
//   console.log('File ID:', fileId);
// });
