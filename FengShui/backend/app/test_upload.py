"""
Test script to upload .usdz file and room data to the analyze-room-with-model endpoint.

This shows the correct format for making the request.
"""
import json
import requests
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent
SAMPLE_JSON = BASE_DIR / "sample.json"
USDZ_FILE = BASE_DIR / "Room.usdz"
API_URL = "http://localhost:8000/analyze-room-with-model"

def test_upload():
    """Test the /analyze-room-with-model endpoint with sample data."""
    
    # Load the JSON data
    with open(SAMPLE_JSON, 'r') as f:
        data = json.load(f)
    
    # Verify .usdz file exists
    if not USDZ_FILE.exists():
        print(f"ERROR: .usdz file not found at {USDZ_FILE}")
        return
    
    print(f"Loading data from {SAMPLE_JSON}")
    print(f"Using .usdz file: {USDZ_FILE}")
    print(f"File size: {USDZ_FILE.stat().st_size / 1024:.1f} KB")
    print()
    
    # Prepare multipart/form-data request
    files = {
        'model_file': ('Room.usdz', open(USDZ_FILE, 'rb'), 'model/vnd.usdz+zip')
    }
    
    # JSON fields must be sent as STRINGS (not JSON objects)
    form_data = {
        'room_metadata': json.dumps(data['room_metadata']),
        'room_dimensions': json.dumps(data['room_dimensions']),
        'objects': json.dumps(data['objects'])
    }
    
    print("Sending request to:", API_URL)
    print("Form fields:")
    print(f"  - room_metadata: {len(form_data['room_metadata'])} chars")
    print(f"  - room_dimensions: {len(form_data['room_dimensions'])} chars")
    print(f"  - objects: {len(form_data['objects'])} chars")
    print(f"  - model_file: {USDZ_FILE.stat().st_size} bytes")
    print()
    
    try:
        # Make the request
        response = requests.post(
            API_URL,
            files=files,
            data=form_data,
            timeout=60
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print()
        
        if response.status_code == 200:
            result = response.json()
            file_id = response.headers.get('X-File-Id', 'N/A')
            
            print("✅ SUCCESS!")
            print(f"File ID: {file_id}")
            print(f"Feng Shui Score: {result.get('feng_shui_score', 'N/A')}/100")
            print(f"Suggestions: {len(result.get('suggestions', []))}")
            print()
            print("To get the optimized model, use:")
            print(f"  GET http://localhost:8000/get-optimized-model/{file_id}")
        else:
            print("❌ ERROR:")
            try:
                error_data = response.json()
                print(json.dumps(error_data, indent=2))
            except:
                print(response.text)
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
    finally:
        # Close the file
        files['model_file'][1].close()

if __name__ == "__main__":
    test_upload()
