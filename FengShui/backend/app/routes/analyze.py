from fastapi import APIRouter
from app.models import AnalyzeRoomRequest, AnalyzeRoomResponse, BaguaAnalysis, Suggestion, UIHints

router = APIRouter()


"""
    Analyze a room and return Feng Shui insights.
    
    Currently returns stub data - will be replaced with real logic in Phase 2.
    
    Uses the following fields from request:
    - room_type: Determines context-aware suggestions (bedroom, office, etc.)
    - room_style: Preferred aesthetic theme (optional)
    - feng_shui_intention: Primary Bagua zone focus (optional, one of 8 zones)
    - birth_year: User's birth year for personalized calculations (optional)
    
    The response prioritizes the feng_shui_intention zone if specified.
"""
@router.post("/analyze-room", response_model=AnalyzeRoomResponse)
async def analyze_room(request: AnalyzeRoomRequest) -> AnalyzeRoomResponse:
    # Determine room type for context-aware suggestions
    room_type = request.room_metadata.room_type.lower()
    
    # Generate realistic stub response based on room type
    if room_type == "bedroom":
        return _generate_bedroom_stub_response(request)
    elif room_type == "office":
        return _generate_office_stub_response(request)
    else:
        return _generate_generic_stub_response(request)

# Function to generate response for bedroom
def _generate_bedroom_stub_response(request: AnalyzeRoomRequest) -> AnalyzeRoomResponse:
    # Find bed object if present
    bed_ids = [obj.id for obj in request.objects if obj.type.lower() == "bed"]
    
    # Get user preferences
    intention = request.room_metadata.feng_shui_intention
    room_style = request.room_metadata.room_style
    birth_year = request.room_metadata.birth_year
    
    # Adjust scores based on intention (stub logic)
    base_scores = {
        "wealth": 65,
        "health": 78,
        "relationships": 70,
        "career": 68,
        "fame": 72,
        "creativity": 70,
        "knowledge": 68,
        "helpful_people": 75
    }
    
    # Boost the intended zone if specified
    if intention and intention in base_scores:
        base_scores[intention] = min(95, base_scores[intention] + 15)
    
    # Generate bagua analysis
    bagua_zones = [
        BaguaAnalysis(zone="wealth", score=base_scores["wealth"], 
                     notes="Bed placement could be improved for wealth energy"),
        BaguaAnalysis(zone="health", score=base_scores["health"], 
                     notes="Good natural light access promotes health"),
        BaguaAnalysis(zone="relationships", score=base_scores["relationships"], 
                     notes="Consider positioning for better relationship energy"),
        BaguaAnalysis(zone="career", score=base_scores["career"], 
                     notes="Room layout supports career growth"),
    ]
    
    # Add personalized note if intention is specified
    if intention:
        for zone in bagua_zones:
            if zone.zone == intention:
                zone.notes += f" (Your focus area - enhanced recommendations available)"
    
    return AnalyzeRoomResponse(
        feng_shui_score=72,
        bagua_analysis=bagua_zones,
        suggestions=[
            Suggestion(
                id="suggestion_1",
                title="Move bed away from door",
                description="Beds aligned with doors reduce rest quality and can disrupt energy flow. Position your bed so it's not directly in line with the door.",
                severity="high",
                related_object_ids=bed_ids[:1] if bed_ids else []
            ),
            Suggestion(
                id="suggestion_2",
                title="Improve natural light access",
                description="Ensure windows are unobstructed to allow positive energy (chi) to flow into the room.",
                severity="medium",
                related_object_ids=[]
            ),
            Suggestion(
                id="suggestion_3",
                title="Reduce clutter",
                description="Clutter blocks energy flow. Keep the space organized and free of unnecessary items.",
                severity="low",
                related_object_ids=[]
            ),
        ],
        ui_hints=UIHints(
            highlight_objects=bed_ids[:1] if bed_ids else [],
            recommended_zones=[intention] if intention else ["health", "relationships"]
        )
    )


# Generate stub response for office
def _generate_office_stub_response(request: AnalyzeRoomRequest) -> AnalyzeRoomResponse:
    # Find desk object if present
    desk_ids = [obj.id for obj in request.objects if obj.type.lower() == "desk"]
    
    # Get user preferences
    intention = request.room_metadata.feng_shui_intention
    room_style = request.room_metadata.room_style
    
    # Adjust scores based on intention (stub logic)
    base_scores = {
        "career": 75,
        "wealth": 70,
        "knowledge": 65
    }
    
    # Boost the intended zone if specified
    if intention and intention in base_scores:
        base_scores[intention] = min(95, base_scores[intention] + 15)
    
    # Generate bagua analysis
    bagua_zones = [
        BaguaAnalysis(zone="career", score=base_scores["career"], 
                     notes="Desk positioning supports career advancement"),
        BaguaAnalysis(zone="wealth", score=base_scores["wealth"], 
                     notes="Good energy flow for prosperity"),
        BaguaAnalysis(zone="knowledge", score=base_scores["knowledge"], 
                     notes="Consider adding plants for knowledge energy"),
    ]
    
    # Add personalized note if intention is specified
    if intention:
        for zone in bagua_zones:
            if zone.zone == intention:
                zone.notes += f" (Your focus area - enhanced recommendations available)"
    
    return AnalyzeRoomResponse(
        feng_shui_score=68,
        bagua_analysis=bagua_zones,
        suggestions=[
            Suggestion(
                id="suggestion_1",
                title="Desk should face the room, not the wall",
                description="Position your desk so you can see the door and room entrance. This 'command position' enhances focus and career success.",
                severity="high",
                related_object_ids=desk_ids[:1] if desk_ids else []
            ),
            Suggestion(
                id="suggestion_2",
                title="Add natural elements",
                description="Incorporate plants or natural materials to balance the energy and improve productivity.",
                severity="medium",
                related_object_ids=[]
            ),
        ],
        ui_hints=UIHints(
            highlight_objects=desk_ids[:1] if desk_ids else [],
            recommended_zones=[intention] if intention else ["career", "wealth"]
        )
    )


# Generate generic stub response for other room types
def _generate_generic_stub_response(request: AnalyzeRoomRequest) -> AnalyzeRoomResponse:
    return AnalyzeRoomResponse(
        feng_shui_score=75,
        bagua_analysis=[
            BaguaAnalysis(zone="wealth", score=70, notes="Room layout supports prosperity"),
            BaguaAnalysis(zone="health", score=75, notes="Good energy flow throughout the space"),
            BaguaAnalysis(zone="relationships", score=72, notes="Space promotes positive interactions"),
        ],
        suggestions=[
            Suggestion(
                id="suggestion_1",
                title="Optimize furniture placement",
                description="Ensure furniture is arranged to allow smooth energy flow throughout the room.",
                severity="medium",
                related_object_ids=[]
            ),
            Suggestion(
                id="suggestion_2",
                title="Maintain clear pathways",
                description="Keep walking paths clear to allow positive energy (chi) to circulate freely.",
                severity="low",
                related_object_ids=[]
            ),
        ],
        ui_hints=UIHints(
            highlight_objects=[],
            recommended_zones=["wealth", "health"]
        )
    )
