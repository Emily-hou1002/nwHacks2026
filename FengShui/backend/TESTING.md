# Testing the API with Postman

## Step 1: Install Dependencies

Open a terminal in the `FengShui/backend/app` directory and run:

```bash
pip install -r requirements.txt
```

Or if you're using a virtual environment:

```bash
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

## Step 2: Start the Server

From the `FengShui/backend/app` directory, run:

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see output like:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Application startup complete.
```

**Server URL:** `http://localhost:8000`

## Step 3: Test Health Check (Optional)

1. Open Postman
2. Create a new **GET** request
3. URL: `http://localhost:8000/health`
4. Click **Send**
5. Expected response:
```json
{
  "status": "healthy"
}
```

## Step 4: Test the Analyze Room Endpoint

### Setup the Request

1. **Method:** Select **POST**
2. **URL:** `http://localhost:8000/analyze-room`
3. **Headers:** 
   - Click **Headers** tab
   - Add: `Content-Type` = `application/json`
4. **Body:**
   - Click **Body** tab
   - Select **raw**
   - Select **JSON** from dropdown
   - Paste one of the sample payloads below

### Sample Request 1: Bedroom

```json
{
  "room_metadata": {
    "room_type": "bedroom",
    "north_direction_deg": 0
  },
  "room_dimensions": {
    "length_m": 4.5,
    "width_m": 3.5,
    "height_m": 2.7
  },
  "objects": [
    {
      "id": "bed_1",
      "type": "bed",
      "position": {
        "x": 2.25,
        "y": 1.0
      },
      "rotation_deg": 90,
      "dimensions": {
        "length_m": 2.0,
        "width_m": 1.5,
        "height_m": 0.5
      }
    },
    {
      "id": "door_1",
      "type": "door",
      "position": {
        "x": 0.0,
        "y": 1.75
      },
      "rotation_deg": 90,
      "dimensions": {
        "length_m": 0.9,
        "width_m": 0.1,
        "height_m": 2.0
      }
    },
    {
      "id": "window_1",
      "type": "window",
      "position": {
        "x": 2.25,
        "y": 0.0
      },
      "rotation_deg": 0,
      "dimensions": {
        "length_m": 1.5,
        "width_m": 0.1,
        "height_m": 1.2
      }
    }
  ]
}
```

### Sample Request 2: Office

```json
{
  "room_metadata": {
    "room_type": "office",
    "north_direction_deg": 0
  },
  "room_dimensions": {
    "length_m": 3.5,
    "width_m": 3.0,
    "height_m": 2.7
  },
  "objects": [
    {
      "id": "desk_1",
      "type": "desk",
      "position": {
        "x": 1.75,
        "y": 1.5
      },
      "rotation_deg": 180,
      "dimensions": {
        "length_m": 1.5,
        "width_m": 0.7,
        "height_m": 0.75
      }
    },
    {
      "id": "door_1",
      "type": "door",
      "position": {
        "x": 0.0,
        "y": 1.5
      },
      "rotation_deg": 90,
      "dimensions": {
        "length_m": 0.9,
        "width_m": 0.1,
        "height_m": 2.0
      }
    }
  ]
}
```

### Sample Request 3: Minimal (Empty Room)

```json
{
  "room_metadata": {
    "room_type": "bedroom"
  },
  "room_dimensions": {
    "length_m": 3.0,
    "width_m": 3.0,
    "height_m": 2.5
  },
  "objects": []
}
```

## Step 5: Send the Request

1. Click **Send** button
2. Check the response in the bottom panel

### Expected Response Format

You should receive a JSON response like:

```json
{
  "feng_shui_score": 72,
  "bagua_analysis": [
    {
      "zone": "wealth",
      "score": 65,
      "notes": "Bed placement could be improved for wealth energy"
    },
    {
      "zone": "health",
      "score": 78,
      "notes": "Good natural light access promotes health"
    }
  ],
  "suggestions": [
    {
      "id": "suggestion_1",
      "title": "Move bed away from door",
      "description": "Beds aligned with doors reduce rest quality and can disrupt energy flow. Position your bed so it's not directly in line with the door.",
      "severity": "high",
      "related_object_ids": ["bed_1"]
    }
  ],
  "ui_hints": {
    "highlight_objects": ["bed_1"],
    "recommended_zones": ["health", "relationships"]
  }
}
```

## Step 6: Test Error Cases

### Test 1: Invalid JSON
- Send malformed JSON
- Expected: 422 error with validation details

### Test 2: Missing Required Fields
```json
{
  "room_metadata": {
    "room_type": "bedroom"
  }
}
```
- Expected: 422 error listing missing fields

### Test 3: Invalid Values
```json
{
  "room_metadata": {
    "room_type": "bedroom"
  },
  "room_dimensions": {
    "length_m": -5.0,
    "width_m": 3.0,
    "height_m": 2.5
  },
  "objects": []
}
```
- Expected: 422 error (negative dimensions not allowed)

## Troubleshooting

**Server won't start:**
- Check if port 8000 is already in use
- Verify all dependencies are installed
- Check Python version (3.8+ required)

**Connection refused:**
- Ensure server is running
- Check URL is correct: `http://localhost:8000/analyze-room`
- Verify firewall isn't blocking

**422 Validation Error:**
- Check JSON syntax is valid
- Verify all required fields are present
- Check field types match schema (numbers, not strings)

**500 Internal Server Error:**
- Check server console for error messages
- Verify all imports are working

## Quick Reference

- **Health Check:** `GET http://localhost:8000/health`
- **Analyze Room:** `POST http://localhost:8000/analyze-room`
- **API Docs:** `GET http://localhost:8000/docs` (FastAPI auto-generated Swagger UI)
- **Alternative Docs:** `GET http://localhost:8000/redoc` (ReDoc format)
