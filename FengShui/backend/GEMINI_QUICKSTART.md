# Gemini AI Quick Setup

## What You Need to Do Before Implementation

### 1. Get Gemini API Key (2 minutes)

**Option A: Google AI Studio (Easiest)**
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with Google account
3. Click "Create API Key"
4. Copy your API key (starts with `AIza...`)

**Option B: Google Cloud Console**
1. Visit: https://console.cloud.google.com/
2. Enable "Generative Language API"
3. Create API credentials
4. Copy API key

### 2. Set Environment Variable

**Windows PowerShell:**
```powershell
$env:AI_API_KEY="your-api-key-here"
$env:USE_AI_ENHANCEMENT="true"
```

**Windows Command Prompt:**
```cmd
set AI_API_KEY=your-api-key-here
set USE_AI_ENHANCEMENT=true
```

**Linux/Mac:**
```bash
export AI_API_KEY="your-api-key-here"
export USE_AI_ENHANCEMENT="true"
```

**Or create `.env` file** in `FengShui/backend/app/`:
```
AI_API_KEY=your-api-key-here
USE_AI_ENHANCEMENT=true
AI_MODEL=gemini-1.5-flash
```

### 3. Install Gemini Package

Already added to `requirements.txt`. Just run:

```bash
cd FengShui/backend/app
pip install -r requirements.txt
```

Or specifically:
```bash
pip install google-generativeai
```

### 4. Verify Setup (Optional Test)

Create a test file `test_gemini.py`:

```python
import os
import google.generativeai as genai

api_key = os.getenv("AI_API_KEY")
if not api_key:
    print("❌ No AI_API_KEY found in environment")
    exit(1)

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-1.5-flash')

try:
    response = model.generate_content("Say 'Gemini is ready!' in one sentence")
    print("✅ Gemini API is working!")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"❌ Error: {e}")
```

Run: `python test_gemini.py`

### 5. Model Options

**Recommended for Hackathon:**
- `gemini-1.5-flash` ✅ (default) - Fast, cheap, powerful enough
- Free tier: 15 requests/minute
- Paid: ~$0.075 per 1M tokens

**Other Options:**
- `gemini-pro` - More capable, slower
- `gemini-1.5-pro` - Latest, most advanced

Change via environment variable:
```bash
export AI_MODEL="gemini-pro"
```

## Checklist Before Implementation

- [ ] API key obtained from Google AI Studio
- [ ] `AI_API_KEY` environment variable set
- [ ] `google-generativeai` package installed (`pip install google-generativeai`)
- [ ] Test API key works (optional but recommended)
- [ ] Ready to implement Gemini integration

## Once You're Ready

Say "ready to implement Gemini" and I'll:
1. Implement `_call_ai_api()` with Gemini
2. Design prompt template for suggestion enhancement
3. Add JSON parsing and response mapping
4. Test with real suggestions

The code is already structured - we just need to fill in the Gemini API calls!
