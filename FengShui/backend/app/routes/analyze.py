import logging
from fastapi import APIRouter
from app.models import AnalyzeRoomRequest, AnalyzeRoomResponse, UIHints
from app.logic.fengshui import FengShuiAnalyzer
from app.services.ai_service import AISuggestionEnhancer
from app.config import USE_AI_ENHANCEMENT, AI_API_KEY

logger = logging.getLogger(__name__)
router = APIRouter()


"""
    Analyze a room and return Feng Shui insights using rule-based logic.
    
    Implements priority rules:
    1. Bed facing door (bedroom)
    2. Desk command position (office)
    3. Clutter density
    4. Natural light access
    5. Clear walking paths
    
    Uses the following fields from request:
    - room_type: Determines context-aware suggestions (bedroom, office, etc.)
    - room_style: Preferred aesthetic theme (optional)
    - feng_shui_intention: Primary Bagua zone focus (optional, one of 9 zones)
    - birth_year: User's birth year for personalized calculations (optional)
    
    The response prioritizes the feng_shui_intention zone if specified.
"""
@router.post("/analyze-room", response_model=AnalyzeRoomResponse)
async def analyze_room(request: AnalyzeRoomRequest) -> AnalyzeRoomResponse:
    # Run Feng Shui analysis (rule-based)
    analyzer = FengShuiAnalyzer(request)
    overall_score, bagua_analysis, suggestions, ui_hints_dict = analyzer.analyze()
    
    # AI Enhancement (optional - disabled by default)
    if USE_AI_ENHANCEMENT:
        logger.info(f"AI enhancement enabled. Enhancing {len(suggestions)} suggestions...")
        ai_enhancer = AISuggestionEnhancer(api_key=AI_API_KEY)
        
        # Check if AI is actually enabled (might be disabled if API key missing)
        if ai_enhancer.enabled:
            # Prepare context for AI
            context = ai_enhancer._prepare_context_for_ai(
                request=request,
                zone_scores={zone.zone: zone.score for zone in bagua_analysis},
                rule_violations=analyzer.rule_violations,
                rule_compliances=analyzer.rule_compliances
            )
            
            # Enhance suggestions with AI
            suggestions = await ai_enhancer.enhance_suggestions(suggestions, context)
        else:
            logger.warning("AI enhancement requested but not available (missing API key or package)")
    else:
        logger.debug(f"AI enhancement disabled. Using {len(suggestions)} rule-based suggestions.")
    
    return AnalyzeRoomResponse(
        feng_shui_score=overall_score,
        bagua_analysis=bagua_analysis,
        suggestions=suggestions,
        ui_hints=UIHints(
            highlight_objects=ui_hints_dict["highlight_objects"],
            recommended_zones=ui_hints_dict["recommended_zones"]
        )
    )
