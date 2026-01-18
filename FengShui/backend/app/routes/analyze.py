from fastapi import APIRouter
from app.models import AnalyzeRoomRequest, AnalyzeRoomResponse, UIHints
from app.logic.fengshui import FengShuiAnalyzer

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
    # Run Feng Shui analysis
    analyzer = FengShuiAnalyzer(request)
    overall_score, bagua_analysis, suggestions, ui_hints_dict = analyzer.analyze()
    
    return AnalyzeRoomResponse(
        feng_shui_score=overall_score,
        bagua_analysis=bagua_analysis,
        suggestions=suggestions,
        ui_hints=UIHints(
            highlight_objects=ui_hints_dict["highlight_objects"],
            recommended_zones=ui_hints_dict["recommended_zones"]
        )
    )
