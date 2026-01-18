from typing import List, Optional, Literal
from pydantic import BaseModel, Field

TOO_LARGE_DIMENSION = 10000

## Request models

# 2D position of an object in the room
class Position(BaseModel):
    x: float = Field(..., description="X coordinate in meters")
    y: float = Field(..., description="Y coordinate in meters")


# 3D dimensions of an object or room
class Dimensions(BaseModel):
    length_m: float = Field(..., description="Length in meters", gt=0, le= TOO_LARGE_DIMENSION)
    width_m: float = Field(..., description="Width in meters", gt=0, le = TOO_LARGE_DIMENSION)
    height_m: float = Field(..., description="Height in meters", gt=0, le = TOO_LARGE_DIMENSION)


# Metadata about the room
class RoomMetadata(BaseModel):
    # Later on we can have defined room_types
    room_type: Optional[Literal[
        "bedroom",
        "living room",
        "office",
        "kitchen",
        "dining room",
        "bathroom",
        "meditation room",
        ]] = Field(
        None,
        description= "Type of room (e.g. bedroom, office, living_room)"
    )
    north_direction_deg: Optional[float] = Field(
        None, 
        description="Direction of north in degrees (0-360)",
        ge=0,
        le=360
    )
    room_style: Optional[Literal[
        "modern",
        "minimalist",
        "traditional",
        "bohemian",
        "zen",
        "industrial",
        "contemporary",
        "rustic",
        "luxury"
    ]] = Field(
        None,
        description="Preferred room aesthetic theme"
    )
    feng_shui_intention: Optional[Literal[
        "wealth",
        "fame",
        "love",
        "health",
        "creativity",
        "knowledge",
        "career",
        "family",
        "balance"
    ]] = Field(
        None,
        description="Primary Feng Shui intention (one of 8 Bagua zones)"
    )
    birth_year: Optional[int] = Field(
        None,
        description="Birth year of the user (for personalized Feng Shui calculations)",
        ge=1900,
        le=2024
    )


# Dimensions of the room
class RoomDimensions(Dimensions):
    ...


# An object in the room
class Object(BaseModel):
    id: str = Field(..., description="Unique identifier for the object")
    type: str = Field(..., description="Type of object (bed, desk, sofa, door, window, plant, etc)")
    position: Position = Field(..., description="2D position of the object")
    rotation_deg: float = Field(..., description="Rotation of the object in degrees", ge=0, le=360)
    dimensions: Dimensions = Field(..., description="3D dimensions of the object")

# Request model for room analysis
class AnalyzeRoomRequest(BaseModel):
    room_metadata: RoomMetadata = Field(..., description="Room metadata")
    room_dimensions: RoomDimensions = Field(..., description="Room dimensions")
    objects: List[Object] = Field(..., description="List of objects in the room", min_length=0)

# Reponse models

# Analysis of a Bagua zone
class BaguaAnalysis(BaseModel):
    zone: str = Field(..., description="Bagua zone name (wealth, health, career, relationships, etc)")
    score: int = Field(..., description="Zone score (0-100)", ge=0, le=100)
    notes: str = Field(..., description="Notes about the zone")

# A Feng Shui suggestion
class Suggestion(BaseModel):
    id: str = Field(..., description="Unique identifier for the suggestion")
    title: str = Field(..., description="Short title of the suggestion")
    description: str = Field(..., description="Detailed description of the suggestion")
    severity: str = Field(..., description="Severity level", pattern="^(low|medium|high)$")
    related_object_ids: List[str] = Field(
        default_factory=list,
        description="IDs of objects related to this suggestion"
    )


# UI hints for frontend visualization
class UIHints(BaseModel):
    highlight_objects: List[str] = Field(
        default_factory=list,
        description="Object IDs that should be highlighted"
    )
    recommended_zones: List[str] = Field(
        default_factory=list,
        description="Bagua zones that should be emphasized"
    )


# Response model for room analysis
class AnalyzeRoomResponse(BaseModel):
    feng_shui_score: int = Field(..., description="Overall Feng Shui score (0-100)", ge=0, le=100)
    bagua_analysis: List[BaguaAnalysis] = Field(..., description="Analysis of each Bagua zone")
    suggestions: List[Suggestion] = Field(..., description="List of Feng Shui suggestions")
    ui_hints: UIHints = Field(..., description="UI hints for frontend")
