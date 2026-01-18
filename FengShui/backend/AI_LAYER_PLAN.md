# AI Layer Implementation Plan

## Current Architecture

```
Request → FengShuiAnalyzer.analyze()
  ├─ Rule-based checks (5 rules)
  ├─ Zone score calculations
  ├─ Generate suggestions (rule-based)
  └─ Return: (score, bagua_analysis, suggestions, ui_hints)
```

## Target Architecture (Hybrid)

```
Request → FengShuiAnalyzer.analyze()
  ├─ Rule-based checks (5 rules) [KEEP]
  ├─ Zone score calculations [KEEP]
  ├─ Generate base suggestions (rule-based) [KEEP]
  └─ AI Enhancement Layer [NEW]
      ├─ Enhance suggestion descriptions
      ├─ Add personalized context
      ├─ Generate additional tips
      └─ Return enhanced suggestions
```

## Step-by-Step Implementation Plan

### STEP 1: Create AI Service Module Structure
**Goal**: Set up the module without actual AI calls (fallback ready)

**Files to create**:
- `FengShui/backend/app/services/__init__.py`
- `FengShui/backend/app/services/ai_service.py`

**Features**:
- AI service class with fallback mechanism
- Configuration for API key (env var)
- Optional AI (works without API key)
- Error handling with fallback to rule-based suggestions

### STEP 2: Define AI Context Data Structure
**Goal**: Structure what we pass to AI

**Data to pass**:
```python
{
  "room_metadata": {...},  # type, style, intention, birth_year
  "room_dimensions": {...},
  "rule_violations": [...],  # detected by rules
  "rule_compliances": [...],  # what's good
  "zone_scores": {...},  # calculated scores
  "current_suggestions": [...]  # rule-based suggestions (to enhance)
}
```

**What AI should return**:
- Enhanced suggestion descriptions
- Additional personalized tips
- Style/intention-specific advice
- Birth year considerations (Chinese astrology)

### STEP 3: Create AI Prompt Template
**Goal**: Design the prompt for AI to enhance suggestions

**Prompt structure**:
1. System role: Feng Shui expert consultant
2. Context: Room data, rule violations, zone scores
3. Task: Enhance suggestions with personalization
4. Format: Structured JSON response

### STEP 4: Integrate AI Service into Analyzer
**Goal**: Add AI enhancement after rule-based analysis

**Integration point**:
- After `FengShuiAnalyzer.analyze()` returns
- Before returning response in `analyze.py`
- Optional: can be disabled via config

### STEP 5: Implement Fallback & Error Handling
**Goal**: Always return suggestions (AI or rule-based)

**Fallback strategy**:
- If AI unavailable → use rule-based suggestions
- If AI returns error → use rule-based suggestions
- If API key missing → use rule-based suggestions
- Log AI failures for debugging

### STEP 6: Add Configuration & Environment Variables
**Goal**: Make AI optional and configurable

**Config options**:
- `USE_AI_ENHANCEMENT`: bool (default: False)
- `AI_API_KEY`: str (optional)
- `AI_MODEL`: str (e.g., "gpt-4o-mini")
- `AI_TIMEOUT`: int (seconds, default: 5)

## Implementation Details

### File Structure

```
FengShui/backend/app/
├── logic/
│   └── fengshui.py          # Rule-based (keep as-is)
├── services/                # NEW
│   ├── __init__.py
│   └── ai_service.py        # AI enhancement service
├── routes/
│   └── analyze.py           # Modify to add AI layer
└── config.py                # NEW: Configuration
```

### AI Service Interface

```python
class AISuggestionEnhancer:
    def __init__(self, api_key: Optional[str] = None):
        self.enabled = api_key is not None
        self.api_key = api_key
    
    async def enhance_suggestions(
        self, 
        rule_suggestions: List[Suggestion],
        context: Dict
    ) -> List[Suggestion]:
        """
        Enhance rule-based suggestions with AI.
        Falls back to rule-based if AI unavailable.
        """
        if not self.enabled:
            return rule_suggestions
        
        try:
            # Call AI API
            enhanced = await self._call_ai(rule_suggestions, context)
            return enhanced
        except Exception as e:
            # Log error, return original
            logger.warning(f"AI enhancement failed: {e}")
            return rule_suggestions
```

### Integration in analyze.py

```python
async def analyze_room(request: AnalyzeRoomRequest):
    # Rule-based analysis (unchanged)
    analyzer = FengShuiAnalyzer(request)
    score, bagua, suggestions, hints = analyzer.analyze()
    
    # AI enhancement (NEW - optional)
    if USE_AI_ENHANCEMENT:
        ai_enhancer = AISuggestionEnhancer(api_key=AI_API_KEY)
        suggestions = await ai_enhancer.enhance_suggestions(
            suggestions, 
            context={...}
        )
    
    return AnalyzeRoomResponse(...)
```

## What AI Will Enhance

### 1. Suggestion Descriptions
**Before** (rule-based):
> "Your bed is positioned in line with the door entrance, which disrupts energy flow."

**After** (AI-enhanced):
> "Your bed is positioned in line with the door entrance, which disrupts energy flow. Based on your modern minimalist style, consider repositioning at a 45-degree angle using a sleek bed frame that maintains your aesthetic while improving energy circulation. This change supports your health intention."

### 2. Additional Personalized Tips
- Birth year considerations (Chinese zodiac compatibility)
- Style-specific placement recommendations
- Intention-focused actionable steps

### 3. Context-Aware Advice
- Room type specific nuances
- Multiple rule interactions
- Subtle optimizations beyond basic rules

## API Choice Considerations

### Option 1: OpenAI GPT-4o-mini (Recommended)
- **Pros**: Fast, reliable, good JSON output, cost-effective
- **Cons**: Requires API key, usage costs
- **Cost**: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens

### Option 2: Anthropic Claude
- **Pros**: Excellent reasoning, longer context
- **Cons**: Higher cost, slower

### Option 3: Local/Open Source (Llama, Mistral)
- **Pros**: No API costs, privacy
- **Cons**: Requires infrastructure, slower, less reliable

### Option 4: Hybrid (Current + Future AI)
- **Pros**: Works immediately, can add AI later
- **Cons**: Less "wow" factor for demo

## Recommended: Start with Fallback-Ready Structure

**Phase 1**: Create service structure with fallback (no AI calls yet)
- All code in place
- Returns rule-based suggestions
- Easy to enable AI later

**Phase 2**: Add AI integration (if time/hackathon allows)
- Add API key configuration
- Implement actual AI calls
- Test with real suggestions

## Success Criteria

✅ Works without AI (always has fallback)
✅ Easy to enable/disable AI
✅ Enhances suggestions when available
✅ No breaking changes to existing API
✅ Graceful error handling
