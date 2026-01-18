import logging
import os
import json
import uuid
from pathlib import Path
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse, Response
from pydantic import ValidationError
from app.models import AnalyzeRoomRequest, AnalyzeRoomResponse, UIHints, RoomMetadata, RoomDimensions, Object
from app.logic.fengshui import FengShuiAnalyzer
from app.services.ai_service import AISuggestionEnhancer
from app.services.usdz_optimizer import USDZOptimizer
from app.config import USE_AI_ENHANCEMENT, AI_API_KEY

logger = logging.getLogger(__name__)
router = APIRouter()

# Directory to store uploaded .usdz files (relative to backend directory)
UPLOAD_DIR = Path(__file__).parent.parent.parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

# Directory to store optimized .usdz files (cache)
OPTIMIZED_DIR = Path(__file__).parent.parent.parent / "optimized"
OPTIMIZED_DIR.mkdir(exist_ok=True)

# Directory to store optimization status/metadata
CACHE_METADATA_DIR = Path(__file__).parent.parent.parent / "cache_metadata"
CACHE_METADATA_DIR.mkdir(exist_ok=True)


# Dependency function to parse and validate form data
async def parse_room_form_data(
    room_metadata: str = Form(..., description="JSON string of room metadata"),
    room_dimensions: str = Form(..., description="JSON string of room dimensions"),
    objects: str = Form(..., description="JSON string of objects array")
) -> AnalyzeRoomRequest:
    """
    Parse and validate the JSON form fields into an AnalyzeRoomRequest.
    Provides clear validation errors if any field is invalid.
    """
    errors = []
    
    # Parse room_metadata
    try:
        metadata_dict = json.loads(room_metadata)
    except json.JSONDecodeError as e:
        errors.append(f"room_metadata: Invalid JSON - {str(e)}")
        metadata_dict = None
    except Exception as e:
        errors.append(f"room_metadata: {str(e)}")
        metadata_dict = None
    
    # Parse room_dimensions
    try:
        dimensions_dict = json.loads(room_dimensions)
    except json.JSONDecodeError as e:
        errors.append(f"room_dimensions: Invalid JSON - {str(e)}")
        dimensions_dict = None
    except Exception as e:
        errors.append(f"room_dimensions: {str(e)}")
        dimensions_dict = None
    
    # Parse objects
    try:
        objects_list = json.loads(objects)
    except json.JSONDecodeError as e:
        errors.append(f"objects: Invalid JSON - {str(e)}")
        objects_list = None
    except Exception as e:
        errors.append(f"objects: {str(e)}")
        objects_list = None
    
    # If JSON parsing failed, raise error with details
    if errors:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "Invalid JSON in form fields",
                "details": errors
            }
        )
    
    # Validate with Pydantic models
    try:
        # Validate individual components first for better error messages
        try:
            validated_metadata = RoomMetadata(**metadata_dict)
        except ValidationError as e:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "Validation error in room_metadata",
                    "field": "room_metadata",
                    "details": e.errors()
                }
            )
        
        try:
            validated_dimensions = RoomDimensions(**dimensions_dict)
        except ValidationError as e:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "Validation error in room_dimensions",
                    "field": "room_dimensions",
                    "details": e.errors()
                }
            )
        
        try:
            validated_objects = [Object(**obj) for obj in objects_list]
        except ValidationError as e:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "Validation error in objects array",
                    "field": "objects",
                    "details": e.errors()
                }
            )
        
        # Build final request
        return AnalyzeRoomRequest(
            room_metadata=validated_metadata,
            room_dimensions=validated_dimensions,
            objects=validated_objects
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "Failed to build AnalyzeRoomRequest",
                "message": str(e)
            }
        )


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


async def validate_file(file):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    file_ext = Path(file.filename).suffix.lower()
    if file_ext != ".usdz":
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type. Expected .usdz, got {file_ext}"
        )
    
    # Validate file size (max 50MB)
    MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
    file_size = 0
    file_content = await file.read()
    file_size = len(file_content)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size is {MAX_FILE_SIZE / (1024*1024):.1f}MB"
        )


async def optimize_model_background(
    file_id: str,
    file_path: Path,
    request: AnalyzeRoomRequest,
    current_score: int,
    enhanced_suggestions_dict: list
):
    """
    Background task to optimize .usdz model with Gemini Vision.
    
    This function:
    1. Takes the enhanced suggestions (already from Gemini)
    2. Sends them along with the .usdz file to Gemini Vision
    3. Gets back transformation suggestions
    4. Applies them to create updated model
    5. Caches the result
    """
    try:
        logger.info(f"🚀 [Background Task] Starting optimization for file_id: {file_id}")
        logger.info(f"   📁 File: {file_path.name} ({file_path.stat().st_size / 1024:.1f}KB)")
        logger.info(f"   📊 Current score: {current_score}/100")
        logger.info(f"   💡 Suggestions to apply: {len(enhanced_suggestions_dict)}")
        
        # Mark as processing
        metadata = {
            "status": "processing",
            "file_id": file_id,
            "current_score": current_score
        }
        metadata_path = CACHE_METADATA_DIR / f"{file_id}.json"
        with open(metadata_path, "w") as f:
            json.dump(metadata, f)
        
        # Optimize with Gemini Vision (using enhanced suggestions)
        optimizer = USDZOptimizer(api_key=AI_API_KEY)
        
        if not optimizer.enabled:
            logger.warning(f"⚠️  [Background Task] USDZ optimization not available for file_id: {file_id}")
            metadata["status"] = "failed"
            metadata["error"] = "USDZ optimization not available"
            with open(metadata_path, "w") as f:
                json.dump(metadata, f)
            return
        
        logger.info(f"🤖 [Background Task] Calling Gemini to analyze layout and suggest transformations...")
        
        # Pass enhanced suggestions + model file to Gemini Vision to create updated model
        optimized_usdz_bytes, transformation_suggestions, new_score = await optimizer.optimize_room_layout(
            usdz_file_path=file_path,
            room_request=request,
            current_score=current_score,
            feng_shui_suggestions=enhanced_suggestions_dict  # These are the enhanced suggestions from step 2
        )
        
        logger.info(f"✅ [Background Task] Gemini analysis complete. Applying {len(transformation_suggestions.get('transformations', []))} transformations...")
        
        # Save optimized model
        optimized_path = OPTIMIZED_DIR / f"{file_id}.usdz"
        with open(optimized_path, "wb") as f:
            f.write(optimized_usdz_bytes)
        
        optimized_size = len(optimized_usdz_bytes)
        logger.info(f"💾 [Background Task] Saved optimized model: {optimized_path.name} ({optimized_size / 1024:.1f}KB)")
        
        # Update metadata
        metadata["status"] = "completed"
        metadata["new_score"] = new_score
        metadata["transformations"] = transformation_suggestions
        metadata["optimized_file_path"] = str(optimized_path)
        with open(metadata_path, "w") as f:
            json.dump(metadata, f)
        
        score_change = new_score - current_score
        logger.info(f"🎉 [Background Task] ✅ COMPLETED for file_id: {file_id}")
        logger.info(f"   📈 Score: {current_score}/100 → {new_score}/100 ({'+' if score_change >= 0 else ''}{score_change:.1f})")
        logger.info(f"   🔗 Retrieve optimized model: GET /get-optimized-model/{file_id}")
        
    except Exception as e:
        import traceback
        logger.error(f"❌ [Background Task] FAILED for file_id: {file_id}")
        logger.error(f"   Error: {str(e)}")
        logger.error(f"   Traceback: {traceback.format_exc()}")
        metadata = {
            "status": "failed",
            "file_id": file_id,
            "error": str(e)
        }
        metadata_path = CACHE_METADATA_DIR / f"{file_id}.json"
        with open(metadata_path, "w") as f:
            json.dump(metadata, f)



## ACTUAL ENDPOINT 
@router.post("/analyze-room-with-model", response_model=AnalyzeRoomResponse)
async def analyze_room_with_model(
    background_tasks: BackgroundTasks,
    model_file: UploadFile = File(..., description="3D model file (.usdz)"),
    request: AnalyzeRoomRequest = Depends(parse_room_form_data)
) -> AnalyzeRoomResponse:
    """
    Analyze a room with a 3D model file (.usdz) and return Feng Shui insights.
    
    Workflow:
    1. Calculate Feng Shui score using deterministic (rule-based) method
    2. Pass score + room data to Gemini to get enhanced suggestions
    3. When enhanced suggestions are received, trigger async background task:
       - Takes enhanced suggestions + model file
       - Sends to Gemini Vision to create updated model
    4. Return enhanced suggestions immediately with file_id in header
    
    The optimized model will be cached and can be retrieved via /get-optimized-model/{file_id}
    """
    # Read file content FIRST (before any validation that might read it)
    file_content = await model_file.read()
    file_size = len(file_content)
    file_ext = Path(model_file.filename).suffix.lower() if model_file.filename else ".usdz"
    
    # Log file size for debugging
    logger.info(f"Received file: {model_file.filename}, size: {file_size} bytes")
    
    # Validate file using the content we already read
    if not model_file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    if file_ext != ".usdz":
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type. Expected .usdz, got {file_ext}"
        )
    
    if file_size == 0:
        raise HTTPException(status_code=400, detail="File is empty")
    
    MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size is {MAX_FILE_SIZE / (1024*1024):.1f}MB"
        )
    
    # Validate it's a valid zip file
    import zipfile
    import io
    try:
        zipfile.ZipFile(io.BytesIO(file_content))
    except zipfile.BadZipFile as e:
        logger.error(f"Invalid .usdz file: {e}")
        raise HTTPException(
            status_code=400,
            detail=f"File is not a valid .usdz file (not a zip archive). Error: {str(e)}"
        )
    
    # Generate unique file_id for this analysis
    file_id = str(uuid.uuid4())
    stored_filename = f"{file_id}{file_ext}"
    file_path = UPLOAD_DIR / stored_filename
    
    try:
        with open(file_path, "wb") as f:
            f.write(file_content)
        logger.info(f"Stored .usdz file: {stored_filename} ({file_size / 1024:.1f}KB)")
    except Exception as e:
        logger.error(f"Failed to store .usdz file: {e}")
        raise HTTPException(status_code=500, detail="Failed to store model file")
    
    # Note: request is already validated by parse_room_form_data dependency
    
    # STEP 1: Calculate Feng Shui score using deterministic (rule-based) method
    analyzer = FengShuiAnalyzer(request)
    overall_score, bagua_analysis, rule_based_suggestions, ui_hints_dict = analyzer.analyze()
    
    # STEP 2: Get enhanced suggestions from Gemini (using score + room data)
    enhanced_suggestions = rule_based_suggestions
    if USE_AI_ENHANCEMENT:
        logger.info(f"Getting enhanced suggestions from Gemini for {len(rule_based_suggestions)} suggestions...")
        ai_enhancer = AISuggestionEnhancer(api_key=AI_API_KEY)
        
        if ai_enhancer.enabled:
            context = ai_enhancer._prepare_context_for_ai(
                request=request,
                zone_scores={zone.zone: zone.score for zone in bagua_analysis},
                rule_violations=analyzer.rule_violations,
                rule_compliances=analyzer.rule_compliances
            )
            enhanced_suggestions = await ai_enhancer.enhance_suggestions(rule_based_suggestions, context)
            logger.info(f"Received {len(enhanced_suggestions)} enhanced suggestions from Gemini")
    
    # Convert enhanced suggestions to dict format for background task
    enhanced_suggestions_dict = [s.model_dump() if hasattr(s, 'model_dump') else dict(s) for s in enhanced_suggestions]
    
    # STEP 3: Trigger async background task to create updated model
    # This task will use the enhanced suggestions + model file with Gemini Vision
    background_tasks.add_task(
        optimize_model_background,
        file_id=file_id,
        file_path=file_path,
        request=request,
        current_score=overall_score,
        enhanced_suggestions_dict=enhanced_suggestions_dict
    )
    logger.info(f"Triggered background optimization task for file_id: {file_id}")
    
    # Return response immediately with score + ENHANCED suggestions + file_id in header
    response = AnalyzeRoomResponse(
        feng_shui_score=overall_score,
        bagua_analysis=bagua_analysis,
        suggestions=enhanced_suggestions,  # Return enhanced suggestions (from Gemini)
        ui_hints=UIHints(
            highlight_objects=ui_hints_dict["highlight_objects"],
            recommended_zones=ui_hints_dict["recommended_zones"]
        )
    )
    
    # Add file_id as custom header so frontend can retrieve optimized model later
    return JSONResponse(
        content=response.model_dump(),
        headers={"X-File-Id": file_id}
    )


## Endpoint to get the optimized model
"""
    Retrieve the optimized .usdz model that was generated in the background.
    
    Returns:
        - Optimized .usdz file if ready
        - Status information if still processing or failed
"""
@router.get("/get-optimized-model/{file_id}")
async def get_optimized_model(file_id: str):
   
    metadata_path = CACHE_METADATA_DIR / f"{file_id}.json"
    
    # Check if metadata exists
    if not metadata_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"Optimization not found for file_id: {file_id}"
        )
    
    # Read metadata
    try:
        with open(metadata_path, "r") as f:
            metadata = json.load(f)
    except Exception as e:
        logger.error(f"Failed to read metadata for {file_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to read optimization status")
    
    status = metadata.get("status", "unknown")
    
    # If still processing, return status
    if status == "processing":
        return JSONResponse(
            content={
                "status": "processing",
                "file_id": file_id,
                "message": "Optimization in progress, please check again later"
            },
            status_code=202  # Accepted but not ready
        )
    
    # If failed, return error
    if status == "failed":
        return JSONResponse(
            content={
                "status": "failed",
                "file_id": file_id,
                "error": metadata.get("error", "Unknown error")
            },
            status_code=500
        )
    
    # If completed, return the optimized file
    if status == "completed":
        optimized_path = Path(metadata.get("optimized_file_path", ""))
        
        if not optimized_path.exists():
            raise HTTPException(
                status_code=404,
                detail="Optimized file not found"
            )
        
        # Read and return the optimized file
        with open(optimized_path, "rb") as f:
            optimized_bytes = f.read()
        
        return Response(
            content=optimized_bytes,
            media_type="model/vnd.usdz+zip",
            headers={
                "Content-Disposition": f'attachment; filename="optimized_room.usdz"',
                "X-Feng-Shui-Score-Before": str(metadata.get("current_score", 0)),
                "X-Feng-Shui-Score-After": str(metadata.get("new_score", 0)),
                "X-Transformations-Count": str(len(metadata.get("transformations", {}).get("transformations", []))),
                "X-Transformations": json.dumps(metadata.get("transformations", {}))
            }
        )
    
    # Unknown status
    raise HTTPException(
        status_code=500,
        detail=f"Unknown optimization status: {status}"
    )
