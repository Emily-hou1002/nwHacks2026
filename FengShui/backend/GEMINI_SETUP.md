# Gemini AI Setup Guide

## Prerequisites Before Implementation

### Step 1: Get Gemini API Key

1. **Go to Google AI Studio**
   - Visit: https://makersuite.google.com/app/apikey
   - Or: https://aistudio.google.com/app/apikey

2. **Create API Key**
   - Sign in with your Google account
   - Click "Create API Key" or "Get API Key"
   - Select or create a Google Cloud project
   - Copy your API key (format: `AIza...`)

3. **Secure Your API Key**
   - Never commit API keys to git
   - Store in environment variable: `AI_API_KEY`
   - For local testing, use `.env` file (add to `.gitignore`)

### Step 2: Install Gemini Python Package

Add to `requirements.txt`:
```
google-generativeai>=0.3.0
```

Then install:
```bash
pip install google-generativeai
```

### Step 3: Configure Environment Variables

**Option A: Environment Variable (Recommended)**
```bash
export AI_API_KEY="your-gemini-api-key-here"
export USE_AI_ENHANCEMENT="true"
export AI_MODEL="gemini-pro"  # or "gemini-1.5-flash" for faster/cheaper
```

**Option B: .env File (Local Development)**
Create `.env` in `FengShui/backend/app/`:
```
AI_API_KEY=your-gemini-api-key-here
USE_AI_ENHANCEMENT=true
AI_MODEL=gemini-pro
```

**Option C: For Windows PowerShell**
```powershell
$env:AI_API_KEY="your-gemini-api-key-here"
$env:USE_AI_ENHANCEMENT="true"
$env:AI_MODEL="gemini-pro"
```

### Step 4: Update Config (Already Done)
The `config.py` already reads from environment variables - no changes needed.

### Step 5: Gemini Model Options

**Available Models:**
- `gemini-pro` - Most capable (recommended)
- `gemini-1.5-flash` - Faster, cheaper, still powerful
- `gemini-1.5-pro` - Latest, most advanced

**For Hackathon:**
- Use `gemini-1.5-flash` - Fast responses, cost-effective
- Free tier: 15 requests per minute
- Paid: Very affordable ($0.075 per 1M input tokens)

### Step 6: Understand Gemini API Structure

**Basic Usage:**
```python
import google.generativeai as genai

genai.configure(api_key="your-api-key")
model = genai.GenerativeModel('gemini-pro')

response = model.generate_content("Your prompt here")
print(response.text)
```

**Async Support:**
- Gemini Python SDK supports async
- Use `asyncio` for async calls
- Or use synchronous calls in async context

**JSON Output:**
- Gemini can return structured JSON
- Use system instructions to specify format
- Parse JSON from response text

### Step 7: Test API Key (Optional)

Create a test script to verify your API key works:

```python
import google.generativeai as genai
import os

api_key = os.getenv("AI_API_KEY")
if not api_key:
    print("No API key found!")
    exit(1)

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-pro')

try:
    response = model.generate_content("Say 'Hello, Feng Shui!' in one sentence")
    print("✅ API Key works!")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"❌ API Key error: {e}")
```

## Implementation Checklist

Before we implement the Gemini integration:

- [ ] API key obtained from Google AI Studio
- [ ] `google-generativeai` package added to requirements.txt
- [ ] Environment variable `AI_API_KEY` set (or .env file)
- [ ] Test API key works (optional but recommended)
- [ ] Decide on model: `gemini-pro` or `gemini-1.5-flash`

## What We'll Implement

1. **Update `ai_service.py`**:
   - Import `google.generativeai`
   - Configure Gemini API
   - Implement `_call_ai_api()` with Gemini
   - Design prompt template for suggestion enhancement

2. **Prompt Design**:
   - System role: Feng Shui expert
   - Context: Room data, violations, scores
   - Task: Enhance suggestion descriptions
   - Output: JSON structure matching Suggestion model

3. **Error Handling**:
   - Handle API rate limits
   - Handle timeout errors
   - Fallback to rule-based suggestions

## Current Status

✅ AI service structure ready
✅ Config reads `AI_API_KEY` from env
✅ Fallback mechanism in place
⏳ Waiting for: Gemini API integration

## Next Steps After Setup

Once you have:
1. ✅ API key
2. ✅ Package installed
3. ✅ Environment variable set

We'll implement:
1. Gemini API calls in `_call_ai_api()`
2. Prompt template for suggestion enhancement
3. JSON parsing and response mapping
4. Testing with real suggestions
