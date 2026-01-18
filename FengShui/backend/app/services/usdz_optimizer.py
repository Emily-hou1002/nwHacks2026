"""
Service for optimizing .usdz files using Gemini Vision API
Analyzes 3D room models and suggests object repositioning to improve Feng Shui
"""
import os
import json
import logging
import zipfile
import tempfile
import re
import math
from pathlib import Path
from typing import Dict, List, Optional, Tuple, BinaryIO
from app.models import AnalyzeRoomRequest

logger = logging.getLogger(__name__)

# Try to import Gemini - fallback if not installed
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-generativeai not installed. USDZ optimization will be disabled.")


class USDZOptimizer:
    """
    Optimizes .usdz 3D room models using Gemini Vision API.
    
    Workflow:
    1. Analyze current room layout with Gemini Vision
    2. Get repositioning suggestions based on Feng Shui rules
    3. Apply transformations to .usdz file
    4. Return optimized .usdz file
    """
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("AI_API_KEY")
        self.enabled = self.api_key is not None and GEMINI_AVAILABLE
        self.model_name = os.getenv("AI_MODEL", "gemini-2.5-flash")
        self.timeout = int(os.getenv("AI_TIMEOUT", "30"))  # Longer timeout for vision analysis
        
        if not GEMINI_AVAILABLE:
            logger.warning("google-generativeai package not installed. USDZ optimization disabled.")
            self.enabled = False
        elif not self.api_key:
            logger.info("USDZ optimization disabled, no API key provided.")
        else:
            try:
                genai.configure(api_key=self.api_key)
                self.gemini_model = genai.GenerativeModel(self.model_name)
                logger.info(f"USDZ Optimizer enabled with model: {self.model_name}")
            except Exception as e:
                logger.warning(f"Failed to configure Gemini for USDZ optimization: {e}")
                self.enabled = False
    
    async def optimize_room_layout(
        self,
        usdz_file_path: Path,
        room_request: AnalyzeRoomRequest,
        current_score: int,
        feng_shui_suggestions: List
    ) -> Tuple[bytes, Dict, int]:
        """
        Optimize room layout by repositioning objects in .usdz file.
        
        Args:
            usdz_file_path: Path to the original .usdz file
            room_request: Room analysis request with metadata and objects
            current_score: Current Feng Shui score
            feng_shui_suggestions: List of Feng Shui suggestions from analysis
            
        Returns:
            Tuple of (optimized_usdz_bytes, transformation_suggestions, new_score)
        """
        if not self.enabled:
            raise RuntimeError("USDZ optimization not enabled (missing API key or package)")
        
        # Step 1: Analyze current layout with Gemini, passing score and suggestions
        suggestions = await self._analyze_layout_with_gemini(
            usdz_file_path, 
            room_request, 
            current_score,
            feng_shui_suggestions
        )
        
        # Step 2: Apply transformations to .usdz file
        # Pass room_request so we can map object_ids to types for better matching
        optimized_usdz_bytes = await self._apply_transformations(
            usdz_file_path, 
            suggestions,
            room_request=room_request
        )
        
        # Step 3: Calculate expected new score
        new_score = self._estimate_new_score(current_score, suggestions)
        
        return optimized_usdz_bytes, suggestions, new_score
    
    async def _analyze_layout_with_gemini(
        self,
        usdz_file_path: Path,
        room_request: AnalyzeRoomRequest,
        current_score: int,
        feng_shui_suggestions: List
    ) -> Dict:
        """
        Use Gemini API to analyze the room layout and suggest object repositioning.
        
        Note: Gemini doesn't support .usdz files directly, so we send structured
        room data (objects, positions, dimensions) as text/JSON instead.
        
        Returns:
            Dictionary with transformation suggestions
        """
        try:
            # Prepare context for Gemini
            context = {
                "room_metadata": {
                    "room_type": room_request.room_metadata.room_type,
                    "room_style": room_request.room_metadata.room_style,
                    "feng_shui_intention": room_request.room_metadata.feng_shui_intention,
                    "birth_year": room_request.room_metadata.birth_year
                },
                "room_dimensions": {
                    "length_m": room_request.room_dimensions.length_m,
                    "width_m": room_request.room_dimensions.width_m,
                    "height_m": room_request.room_dimensions.height_m
                },
                "current_objects": [
                    {
                        "id": obj.id,
                        "type": obj.type,
                        "position": {"x": obj.position.x, "y": obj.position.y},
                        "rotation_deg": obj.rotation_deg,
                        "dimensions": {
                            "length_m": obj.dimensions.length_m,
                            "width_m": obj.dimensions.width_m,
                            "height_m": obj.dimensions.height_m
                        }
                    }
                    for obj in room_request.objects
                ],
                "current_feng_shui_score": current_score
            }
            
            # Build prompt for Gemini (include Feng Shui suggestions)
            prompt = self._build_optimization_prompt(context, feng_shui_suggestions)
            
            # Call Gemini with structured data (text prompt)
            # Note: Gemini doesn't support .usdz files, so we send structured room data instead
            import asyncio
            response = await asyncio.to_thread(
                lambda: self._call_gemini_text(prompt)
            )
            
            # Parse Gemini response to extract transformation suggestions
            suggestions = self._parse_gemini_response(response)
            
            logger.info(f"Gemini suggested {len(suggestions.get('transformations', []))} object transformations")
            return suggestions
            
        except Exception as e:
            logger.error(f"Error analyzing layout with Gemini: {e}")
            raise
    
    def _call_gemini_vision(self, usdz_file_path: Path, prompt: str) -> str:
        """
        Call Gemini Vision API with .usdz file.
        
        Gemini File API requires uploading the file first, then referencing it.
        """
        # Upload file to Gemini File API
        uploaded_file = genai.upload_file(
            path=str(usdz_file_path),
            mime_type="model/vnd.usdz+zip"
        )
        
        # Wait for file to be processed
        import time
        while uploaded_file.state.name == "PROCESSING":
            time.sleep(2)
            uploaded_file = genai.get_file(uploaded_file.name)
        
        if uploaded_file.state.name == "FAILED":
            raise RuntimeError(f"File upload failed: {uploaded_file.state}")
        
        # Generate content with file and prompt
        response = self.gemini_model.generate_content([
            uploaded_file,
            prompt
        ])
        
        # Clean up uploaded file
        try:
            genai.delete_file(uploaded_file.name)
        except:
            pass
        
        return response.text
    
    def _call_gemini_text(self, prompt: str) -> str:
        """
        Call Gemini API with text prompt containing structured room data.
        
        Since Gemini doesn't support .usdz files, we send the room layout
        as structured JSON/text data in the prompt instead.
        """
        # Generate content with text prompt only
        response = self.gemini_model.generate_content(prompt)
        
        if not response.text:
            raise RuntimeError("Empty response from Gemini API")
        
        return response.text
    
    def _build_optimization_prompt(self, context: Dict, feng_shui_suggestions: List) -> str:
        """Build prompt for Gemini to suggest object repositioning based on Feng Shui analysis."""
        room_type = context["room_metadata"].get("room_type", "room")
        intention = context["room_metadata"].get("feng_shui_intention", "")
        current_score = context.get("current_feng_shui_score", 0)
        
        # Format Feng Shui suggestions for the prompt
        suggestions_text = "\n".join([
            f"- [{s.get('id', 'unknown')}] {s.get('title', '')}: {s.get('description', '')} (Severity: {s.get('severity', 'medium')})"
            for s in feng_shui_suggestions
        ])
        
        prompt = f"""You are an expert Feng Shui consultant analyzing a 3D room model.

CURRENT ROOM LAYOUT:
- Room Type: {room_type}
- Feng Shui Intention: {intention if intention else 'Not specified'}
- Current Feng Shui Score: {current_score}/100
- Room Dimensions: {context['room_dimensions']}
- Objects: {json.dumps(context['current_objects'], indent=2)}

FENG SHUI ANALYSIS RESULTS:
The room has been analyzed and the following issues/suggestions were identified:
{suggestions_text}

TASK:
Analyze the 3D model (.usdz file) and suggest SPECIFIC object repositioning to address the Feng Shui issues above.
Your goal is to improve the Feng Shui score from {current_score}/100 to a higher score.

REQUIREMENTS:
1. Address the specific Feng Shui suggestions listed above
2. Suggest concrete new positions (x, y coordinates) and rotations for objects
3. Ensure objects don't overlap or go outside room boundaries
4. Maintain clear walking paths
5. Align with Feng Shui intention: {intention if intention else 'general balance'}

OUTPUT FORMAT (JSON):
{{
  "transformations": [
    {{
      "object_id": "bed_1",
      "new_position": {{"x": 2.5, "y": 1.2}},
      "new_rotation_deg": 45,
      "reason": "Moved bed away from door alignment to address 'bed_door_alignment' issue",
      "addresses_suggestion_id": "suggestion_1",
      "expected_score_improvement": 5
    }}
  ],
  "summary": "Overall improvement strategy based on Feng Shui analysis",
  "expected_new_score": {min(100, current_score + 10)}
}}

IMPORTANT:
- Return ONLY valid JSON, no markdown formatting
- Use the exact object_ids from the objects list above
- Ensure new positions are within room boundaries
- Address as many Feng Shui suggestions as possible"""
        
        return prompt
    
    def _parse_gemini_response(self, response_text: str) -> Dict:
        """Parse Gemini's JSON response into transformation suggestions."""
        try:
            # Remove markdown code blocks if present
            text = response_text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]
            text = text.strip()
            
            suggestions = json.loads(text)
            return suggestions
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response: {e}")
            logger.debug(f"Response text: {response_text[:500]}")
            return {"transformations": [], "summary": "Failed to parse suggestions"}
    
    async def _apply_transformations(
        self,
        usdz_file_path: Path,
        suggestions: Dict,
        room_request: Optional[AnalyzeRoomRequest] = None
    ) -> bytes:
        """
        Apply transformation suggestions to .usdz file.
        
        .usdz is a zip file (no compression) containing USD files.
        Steps:
        1. Extract the .usdz to temp directory
        2. Find and parse USD files (USDA text format or USDC binary)
        3. Update object transforms based on suggestions
        4. Re-zip into new .usdz (no compression, store method)
        """
        transformations = suggestions.get("transformations", [])

        # Hackathon-safe guardrail:
        # If the scene is mostly/only chairs+desks, Gemini often collapses targets and causes stacking.
        # Cap how many transforms we apply for these crowded types to keep the output stable.
        transformations = self._cap_transformations_for_crowded_scenes(transformations, room_request)
        
        if not transformations:
            # No changes, return original file
            logger.info("No transformations to apply")
            with open(usdz_file_path, "rb") as f:
                return f.read()
        
        logger.info(f"Applying {len(transformations)} transformations to .usdz file")
        
        # Create temporary directory for extraction
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            
            # Step 1: Validate and extract .usdz (it's a zip with no compression)
            # First check if file exists and is readable
            if not usdz_file_path.exists():
                logger.error(f".usdz file not found: {usdz_file_path}")
                raise FileNotFoundError(f"USDZ file not found: {usdz_file_path}")
            
            # Check file size
            file_size = usdz_file_path.stat().st_size
            if file_size == 0:
                logger.error(f".usdz file is empty: {usdz_file_path}")
                raise ValueError(f"USDZ file is empty: {usdz_file_path}")
            
            logger.info(f"Attempting to extract .usdz file: {usdz_file_path} ({file_size / 1024:.1f}KB)")
            
            # Validate it's a zip file before extracting
            if not zipfile.is_zipfile(usdz_file_path):
                logger.error(f"File is not a valid zip archive: {usdz_file_path}")
                # Try to read first few bytes to see what it is
                with open(usdz_file_path, "rb") as f:
                    first_bytes = f.read(10)
                    logger.error(f"First 10 bytes: {first_bytes.hex()}")
                raise ValueError(f"File is not a valid .usdz (zip) archive. File size: {file_size} bytes")
            
            # Extract .usdz (it's a zip with no compression)
            try:
                with zipfile.ZipFile(usdz_file_path, 'r') as zip_ref:
                    # Test zip file integrity
                    bad_file = zip_ref.testzip()
                    if bad_file:
                        logger.warning(f"Zip file has bad entry: {bad_file}")
                    
                    zip_ref.extractall(temp_path)
                logger.debug(f"Successfully extracted .usdz to {temp_path}")
            except zipfile.BadZipFile as e:
                logger.error(f"Bad zip file: {e}")
                raise ValueError(f"Invalid .usdz file (corrupted zip archive): {e}")
            except Exception as e:
                logger.error(f"Failed to extract .usdz: {e}")
                raise RuntimeError(f"Failed to extract .usdz file: {e}")
            
            # Step 2: Find USD files
            usd_files = list(temp_path.rglob("*.usd*"))
            usda_files = [f for f in usd_files if f.suffix in ['.usda', '.usd']]
            usdc_files = [f for f in usd_files if f.suffix == '.usdc']
            
            if not usda_files and not usdc_files:
                logger.warning("No USD files found in .usdz archive")
                with open(usdz_file_path, "rb") as f:
                    return f.read()

            # Determine a floor "Y" level to avoid sinking objects.
            # RoomPlan exports include Floor*.usda meshes; we use their transform translation Y.
            self._current_floor_y = self._detect_floor_y(temp_path)
            # Prefer bounds derived from the floor mesh (prevents "in wall" for partial scans)
            self._current_plan_bounds = self._detect_floor_bounds_xy(temp_path)

            # Now that we have scene-derived bounds, normalize and de-overlap transformations.
            transformations = self._normalize_and_spread_transformations(transformations, room_request)

            # Step 3: Modify USD files based on transformations
            # NOTE: A .usdz commonly contains MANY .usda files (one per object).
            # Modifying only the "first" file is non-deterministic and can corrupt prim headers.
            try:
                total_applied = 0

                # Prefer editing text-based USDAs; leave USDC alone for now.
                for text_usd_file in sorted(usda_files, key=lambda p: (len(p.parts), p.name.lower())):
                    modified_content, applied = self._modify_usda_file(text_usd_file, transformations, room_request)
                    if applied <= 0:
                        continue

                    # Validate modified content is not empty and has basic USD structure
                    if not modified_content or len(modified_content.strip()) == 0:
                        logger.error(f"Modified USD file is empty: {text_usd_file}")
                        raise ValueError("USD file modification resulted in empty file")

                    # Write modified content
                    with open(text_usd_file, 'w', encoding='utf-8') as f:
                        f.write(modified_content)

                    total_applied += applied
                    logger.info(f"✅ Applied {applied} transform(s) in {text_usd_file.relative_to(temp_path)}")

                if usdc_files:
                    logger.warning(
                        f"USDC binary format detected ({len(usdc_files)} file(s)). "
                        f"These are not modified by the current optimizer."
                    )

                logger.info(f"📦 Total transforms applied across USD files: {total_applied}")
            except Exception as e:
                logger.error(f"Failed to modify USD file: {e}")
                import traceback
                logger.error(f"Traceback: {traceback.format_exc()}")
                # Return original on error
                with open(usdz_file_path, "rb") as f:
                    return f.read()
            finally:
                # Don't leak state across requests
                self._current_floor_y = None
                self._current_plan_bounds = None
            
            # Step 4: Re-zip into new .usdz (no compression, store method)
            output_path = temp_path / "optimized.usdz"
            try:
                # Get list of files from original zip to preserve order and structure
                original_file_list = []
                with zipfile.ZipFile(usdz_file_path, 'r') as zip_in:
                    original_file_list = zip_in.namelist()
                
                # Create new zip with same structure
                with zipfile.ZipFile(output_path, 'w', compression=zipfile.ZIP_STORED) as zip_out:
                    # Add files in the same order as original, maintaining exact structure
                    for arcname_str in original_file_list:
                        # Convert zip path to local path (handle both / and \)
                        local_path = temp_path / arcname_str.replace('/', os.sep)
                        
                        if local_path.exists() and local_path.is_file():
                            # Read file content
                            with open(local_path, 'rb') as f:
                                file_data = f.read()
                            
                            # Write to zip with original name (using forward slashes)
                            zip_out.writestr(arcname_str, file_data, compress_type=zipfile.ZIP_STORED)
                        else:
                            logger.warning(f"File from original zip not found: {local_path}")
                    
                    # Also add any new/modified files that might not be in original list
                    for file_path in sorted(temp_path.rglob("*")):
                        if file_path.is_file() and file_path != output_path:
                            arcname = file_path.relative_to(temp_path)
                            arcname_str = str(arcname).replace('\\', '/')
                            
                            # Only add if not already in zip
                            if arcname_str not in original_file_list:
                                with open(file_path, 'rb') as f:
                                    file_data = f.read()
                                zip_out.writestr(arcname_str, file_data, compress_type=zipfile.ZIP_STORED)
                
                # Validate the zip file before returning
                try:
                    with zipfile.ZipFile(output_path, 'r') as test_zip:
                        bad_file = test_zip.testzip()
                        if bad_file:
                            raise ValueError(f"Corrupted zip entry: {bad_file}")
                    logger.debug(f"✅ Zip file validation passed")
                except zipfile.BadZipFile as e:
                    logger.error(f"Created zip file is corrupted: {e}")
                    raise ValueError(f"Failed to create valid .usdz file: {e}")
                
                # Read the new .usdz file
                with open(output_path, "rb") as f:
                    optimized_bytes = f.read()
                
                original_size = usdz_file_path.stat().st_size
                logger.info(f"✅ Successfully created optimized .usdz ({len(optimized_bytes) / 1024:.1f}KB, original: {original_size / 1024:.1f}KB)")
                return optimized_bytes
                
            except Exception as e:
                logger.error(f"Failed to create new .usdz: {e}")
                # Return original on error
                with open(usdz_file_path, "rb") as f:
                    return f.read()
    
    def _modify_usda_file(
        self,
        usd_file: Path,
        transformations: List[Dict],
        room_request: Optional[AnalyzeRoomRequest] = None
    ) -> Tuple[str, int]:
        """
        Modify USDA (text-based USD) file to apply transformations.

        IMPORTANT:
        - We must insert xform ops inside the prim body "{ ... }", NOT inside the prim
          metadata parentheses "( ... )". A previous streaming parser could insert
          inside "( ... )", producing USD parse errors like "Expected )".
        - Many scenes store a stable UUID in prim customData (e.g. `string UUID = "..."`).
          We prefer matching by that UUID (exact) rather than guessing by prim name/type.

        Returns:
            (modified_text, applied_count)
        """
        with open(usd_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Build object_id -> type mapping (optional; used only as a last-resort fallback)
        object_id_to_type: Dict[str, str] = {}
        if room_request:
            for obj in room_request.objects:
                if obj.id:
                    object_id_to_type[str(obj.id).lower()] = obj.type.lower()

        # Normalize transformation map by lowercase UUID/object_id
        transform_map: Dict[str, Dict] = {}
        for trans in transformations:
            obj_id = str(trans.get("object_id", "") or "").strip()
            if not obj_id:
                continue
            key = obj_id.lower()
            transform_map[key] = trans
            if "object_type" not in trans:
                trans["object_type"] = object_id_to_type.get(key, "")

        if not transform_map:
            return ''.join(lines), 0

        # Identify Xform blocks with proper brace matching:
        # def Xform "Name" ( ... ) { ... }
        def_xform_re = re.compile(r'^\s*def\s+Xform\s+"([^"]+)"')
        uuid_re = re.compile(r'^\s*string\s+UUID\s*=\s*"([^"]+)"')

        xform_blocks: List[Tuple[int, int, str, Optional[str]]] = []  # (def_idx, close_idx, name, uuid)
        for def_idx, line in enumerate(lines):
            m = def_xform_re.search(line)
            if not m:
                continue

            xform_name = m.group(1)

            # Find the opening brace for THIS prim body "{ ... }".
            # Do NOT grab braces in metadata dicts like `assetInfo = { ... }` inside "( ... )".
            # Strategy:
            # - If the prim has a metadata header "( ... )", first find the line where that header closes.
            # - Then find the first subsequent line that starts the prim body "{" at the prim level.
            header_end_idx = def_idx
            paren_count = line.count('(') - line.count(')')
            if paren_count > 0:
                for j in range(def_idx + 1, len(lines)):
                    paren_count += lines[j].count('(') - lines[j].count(')')
                    if paren_count <= 0:
                        header_end_idx = j
                        break

            open_idx = None
            for j in range(header_end_idx, len(lines)):
                if '{' in lines[j] and lines[j].lstrip().startswith('{'):
                    open_idx = j
                    break

            if open_idx is None:
                continue

            # Find matching closing brace for this block
            brace_count = 0
            close_idx = None
            for k in range(open_idx, len(lines)):
                brace_count += lines[k].count('{') - lines[k].count('}')
                if brace_count == 0:
                    close_idx = k
                    break

            if close_idx is None:
                continue

            # Try to extract UUID from within the prim definition (customData)
            prim_uuid = None
            for t in range(def_idx, min(close_idx + 1, len(lines))):
                um = uuid_re.search(lines[t])
                if um:
                    prim_uuid = um.group(1)
                    break

            xform_blocks.append((def_idx, close_idx, xform_name, prim_uuid))

        if not xform_blocks:
            return ''.join(lines), 0

        # Decide which blocks to modify.
        # Prefer exact UUID match from customData. Fall back to name-based match ONLY if needed.
        planned_mods: List[Tuple[int, int, str, Dict]] = []
        used_transform_keys: set[str] = set()

        for def_idx, close_idx, xform_name, prim_uuid in xform_blocks:
            chosen: Optional[Dict] = None

            if prim_uuid:
                uuid_key = prim_uuid.lower()
                if uuid_key in transform_map and uuid_key not in used_transform_keys:
                    chosen = transform_map[uuid_key]
                    used_transform_keys.add(uuid_key)

            if chosen is None:
                xform_lower = xform_name.lower()
                # Very conservative fallback: only if a transform key appears in prim name
                for key, trans in transform_map.items():
                    if key in used_transform_keys:
                        continue
                    if key in xform_lower or xform_lower in key:
                        chosen = trans
                        used_transform_keys.add(key)
                        break

            if chosen is not None:
                planned_mods.append((def_idx, close_idx, xform_name, chosen))

        if not planned_mods:
            return ''.join(lines), 0

        # Apply from bottom to top so earlier indices remain valid.
        applied = 0
        for def_idx, close_idx, xform_name, trans in sorted(planned_mods, key=lambda x: x[0], reverse=True):
            try:
                self._apply_transform_to_xform(lines, def_idx, close_idx, xform_name, trans)
                applied += 1
            except Exception as e:
                logger.warning(f"Failed to apply transform to Xform '{xform_name}' in {usd_file.name}: {e}")

        return ''.join(lines), applied
    
    def _parse_existing_transform(self, lines: List[str], start_idx: int, end_idx: int) -> Dict:
        """Parse existing transform from Xform block to preserve scale and other properties."""
        existing = {
            "has_matrix": False,
            "has_translate": False,
            "has_rotate": False,
            "has_scale": False,
            "scale": (1.0, 1.0, 1.0),
            "translate": (0.0, 0.0, 0.0),
            "matrix_line": None,
            "matrix_line_idx": None
        }
        
        for i in range(start_idx, min(end_idx + 1, len(lines))):
            line = lines[i]
            
            # Check for matrix transform
            if 'xformOp:transform' in line and 'matrix4d' in line:
                existing["has_matrix"] = True
                existing["matrix_line"] = line
                existing["matrix_line_idx"] = i
                # Extract numeric components from the matrix line.
                # USD ASCII matrix often looks like:
                # matrix4d ... = ( (a,b,c,d), (e,f,g,h), (i,j,k,l), (tx,ty,tz,1) )
                try:
                    # NOTE: avoid matching the "4" in "matrix4d" (and similar tokens like normal3f).
                    nums = re.findall(
                        r'[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?(?![A-Za-z_])',
                        line
                    )
                    values = [float(n) for n in nums]
                    if len(values) >= 16:
                        m00, m01, m02, m03 = values[0:4]
                        m10, m11, m12, m13 = values[4:8]
                        m20, m21, m22, m23 = values[8:12]
                        tx, ty, tz, tw = values[12:16]

                        # Scale is the length of each basis column/row depending on convention.
                        # In typical USD ASCII here, rows encode the basis for X,Y,Z.
                        scale_x = math.sqrt(m00**2 + m01**2 + m02**2)
                        scale_y = math.sqrt(m10**2 + m11**2 + m12**2)
                        scale_z = math.sqrt(m20**2 + m21**2 + m22**2)
                        if scale_x > 0 and scale_y > 0 and scale_z > 0:
                            existing["scale"] = (scale_x, scale_y, scale_z)
                        existing["translate"] = (tx, ty, tz)
                except Exception:
                    pass
            
            # Check for separate translate/rotate/scale operations
            if 'xformOp:translate' in line:
                existing["has_translate"] = True
                translate_match = re.search(r'\(([^)]+)\)', line)
                if translate_match:
                    try:
                        t_vals = [float(v.strip()) for v in translate_match.group(1).split(',')]
                        if len(t_vals) >= 3:
                            existing["translate"] = (t_vals[0], t_vals[1], t_vals[2])
                    except Exception:
                        pass
            if 'xformOp:rotate' in line or 'xformOp:orient' in line:
                existing["has_rotate"] = True
            if 'xformOp:scale' in line:
                existing["has_scale"] = True
                # Extract scale values
                scale_match = re.search(r'\(([^)]+)\)', line)
                if scale_match:
                    try:
                        scale_vals = [float(v.strip()) for v in scale_match.group(1).split(',')]
                        if len(scale_vals) >= 3:
                            existing["scale"] = tuple(scale_vals[:3])
                    except:
                        pass
        
        return existing

    def _detect_floor_y(self, extracted_root: Path) -> Optional[float]:
        """
        Best-effort detection of the floor's Y translation from extracted USDAs.

        Returns:
            floor_y (float) if found, else None.
        """
        try:
            floor_files = sorted(extracted_root.rglob("assets/Mesh/Floors/*.usda"))
            if not floor_files:
                return None

            # Same numeric matcher we use elsewhere (avoid "matrix4d" matching 4)
            num_re = re.compile(r'[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?(?![A-Za-z_])')

            floor_ys: List[float] = []
            for f in floor_files:
                text = f.read_text(encoding="utf-8", errors="ignore")
                for line in text.splitlines():
                    if "matrix4d" in line and "xformOp:transform" in line:
                        nums = [float(n) for n in num_re.findall(line)]
                        if len(nums) >= 16:
                            # Translation is last row: (tx, ty, tz, 1)
                            ty = nums[13]
                            floor_ys.append(ty)
                        break

            if not floor_ys:
                return None

            # Use the minimum Y (most conservative "floor" level)
            return float(min(floor_ys))
        except Exception:
            return None

    def _detect_floor_bounds_xy(self, extracted_root: Path) -> Optional[Tuple[float, float, float, float]]:
        """
        Best-effort detection of usable floor bounds from Floor*.usda mesh points + transform.

        Returns:
            (min_x, max_x, min_y, max_y) in the request's 2D plane where:
            - request x == USD X
            - request y == USD Z
        """
        try:
            floor_files = sorted(extracted_root.rglob("assets/Mesh/Floors/*.usda"))
            if not floor_files:
                return None

            # Avoid matching the "4" in "matrix4d", etc.
            num_re = re.compile(r'[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?(?![A-Za-z_])')
            triple_re = re.compile(
                r'\(\s*([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)\s*,'
                r'\s*([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)\s*,'
                r'\s*([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)\s*\)'
            )

            all_x: List[float] = []
            all_z: List[float] = []

            for f in floor_files:
                text = f.read_text(encoding="utf-8", errors="ignore")
                matrix_line = None
                points_line = None
                for line in text.splitlines():
                    if matrix_line is None and "matrix4d" in line and "xformOp:transform" in line:
                        matrix_line = line
                    if points_line is None and "point3f[] points" in line:
                        points_line = line
                    if matrix_line and points_line:
                        break

                if not matrix_line or not points_line:
                    continue

                nums = [float(n) for n in num_re.findall(matrix_line)]
                if len(nums) < 16:
                    continue

                # Row-major 4x4 matrix
                M = [
                    nums[0:4],
                    nums[4:8],
                    nums[8:12],
                    nums[12:16],
                ]

                pts = [(float(a), float(b), float(c)) for a, b, c in triple_re.findall(points_line)]
                if not pts:
                    continue

                for px, py, pz in pts:
                    # Transform point by M, and take X/Z (Y-up)
                    xw = px * M[0][0] + py * M[1][0] + pz * M[2][0] + 1.0 * M[3][0]
                    zw = px * M[0][2] + py * M[1][2] + pz * M[2][2] + 1.0 * M[3][2]
                    all_x.append(float(xw))
                    all_z.append(float(zw))

            if not all_x or not all_z:
                return None

            # Convert USD X/Z to request x/y
            return (min(all_x), max(all_x), min(all_z), max(all_z))
        except Exception:
            return None

    def _cap_transformations_for_crowded_scenes(
        self,
        transformations: List[Dict],
        room_request: Optional[AnalyzeRoomRequest],
        *,
        max_desks: int = 1,
        max_chairs: int = 1,
    ) -> List[Dict]:
        """
        Limit how many desk/chair transforms we apply.

        This is a pragmatic hackathon guardrail: rooms with many chairs/desks frequently
        get duplicate target positions from the model, which leads to stacking.

        By default we:
        - apply up to 1 desk transform
        - apply up to 1 chair transform
        - apply all non-desk/chair transforms (if present)
        """
        if not transformations or not room_request:
            return transformations

        type_by_id: Dict[str, str] = {}
        for obj in room_request.objects:
            try:
                type_by_id[str(obj.id).lower()] = str(obj.type).lower()
            except Exception:
                continue

        def score(t: Dict) -> float:
            try:
                return float(t.get("expected_score_improvement", 0) or 0)
            except Exception:
                return 0.0

        desks: List[Dict] = []
        chairs: List[Dict] = []
        other: List[Dict] = []

        for t in transformations:
            if not isinstance(t, dict):
                continue
            obj_id = str(t.get("object_id", "") or "").strip().lower()
            if not obj_id:
                continue
            typ = type_by_id.get(obj_id, "")
            if typ == "desk":
                desks.append(t)
            elif typ == "chair":
                chairs.append(t)
            else:
                other.append(t)

        # Sort deterministically: best improvement first, then stable by object_id
        desks = sorted(desks, key=lambda t: (-score(t), str(t.get("object_id", ""))))
        chairs = sorted(chairs, key=lambda t: (-score(t), str(t.get("object_id", ""))))

        capped = other + desks[: max(0, int(max_desks))] + chairs[: max(0, int(max_chairs))]

        # If literally everything is chairs/desks, this may intentionally return a tiny set (or empty).
        if len(capped) != len(transformations):
            logger.info(
                f"🧰 Capped transformations for crowded scene: {len(transformations)} → {len(capped)} "
                f"(kept desks={min(len(desks), max_desks)}, chairs={min(len(chairs), max_chairs)}, other={len(other)})"
            )

        return capped

    def _normalize_and_spread_transformations(
        self,
        transformations: List[Dict],
        room_request: Optional[AnalyzeRoomRequest]
    ) -> List[Dict]:
        """
        Clean and stabilize transformation list.

        Fixes two common real-world issues:
        - Missing/invalid new_position fields (otherwise we'd default to (0,0) and stack objects)
        - Multiple objects assigned the exact same target position (spread them slightly)
        """
        if not transformations:
            return []

        # Build object dimension/type/original-position lookup for better spacing/bounds
        dims_by_id: Dict[str, Tuple[float, float]] = {}
        type_by_id: Dict[str, str] = {}
        orig_pos_by_id: Dict[str, Tuple[float, float]] = {}
        # Bounds used for clamping/placement in the (x,y) plane used by the request.
        # NOTE: For partial scans (e.g., only 2 walls), `room_dimensions` can be a poor proxy
        # for the usable area. We prefer bounds inferred from the original object positions.
        room_bounds = getattr(self, "_current_plan_bounds", None)  # (min_x, max_x, min_y, max_y)
        if room_request:
            for obj in room_request.objects:
                try:
                    obj_key = str(obj.id).lower()
                    dims_by_id[obj_key] = (
                        float(obj.dimensions.length_m),
                        float(obj.dimensions.width_m),
                    )
                    type_by_id[obj_key] = str(obj.type).lower()
                    orig_pos_by_id[obj_key] = (float(obj.position.x), float(obj.position.y))
                except Exception:
                    continue

            # If we couldn't infer bounds from the floor mesh, fall back to observed object bounds.
            if not room_bounds:
                try:
                    xs = [p[0] for p in orig_pos_by_id.values()]
                    ys = [p[1] for p in orig_pos_by_id.values()]
                    if xs and ys:
                        # Add padding so we don't clamp everyone onto the same boundary.
                        pad = 0.35
                        room_bounds = (min(xs) - pad, max(xs) + pad, min(ys) - pad, max(ys) + pad)
                except Exception:
                    room_bounds = None

        cleaned: List[Dict] = []
        for t in transformations:
            if not isinstance(t, dict):
                continue

            obj_id = str(t.get("object_id", "") or "").strip()
            pos = t.get("new_position")
            if not obj_id or not isinstance(pos, dict):
                continue

            # Require both x and y; don't default to 0.0
            if "x" not in pos or "y" not in pos:
                continue

            try:
                x = float(pos["x"])
                y = float(pos["y"])
            except Exception:
                continue

            # Rotation optional; normalize if present
            if "new_rotation_deg" in t:
                try:
                    t["new_rotation_deg"] = float(t["new_rotation_deg"])
                except Exception:
                    t.pop("new_rotation_deg", None)

            t["object_id"] = obj_id
            t["new_position"] = {"x": x, "y": y}
            cleaned.append(t)

        if not cleaned:
            return []

        # If Gemini collapses many objects of the same type to a single target, preserve their
        # original relative spacing by applying a group delta.
        #
        # Example: 10 chairs all get `new_position: {x: 1.2, y: 3.4}`.
        # Instead of stacking them, compute the original chair centroid and translate every chair
        # by (target_centroid - original_centroid).
        def pos_key(p: Dict) -> Tuple[int, int]:
            # bucket to ~2cm to treat near-identical as identical
            return (int(round(float(p["x"]) * 50)), int(round(float(p["y"]) * 50)))

        by_type: Dict[str, List[Dict]] = {}
        for t in cleaned:
            obj_key = str(t.get("object_id", "")).lower()
            obj_type = type_by_id.get(obj_key, "")
            if obj_type:
                by_type.setdefault(obj_type, []).append(t)

        for obj_type, ts in by_type.items():
            if len(ts) < 2:
                continue

            # Only apply this heuristic for "many" items (chairs/desks commonly)
            if obj_type not in {"chair", "desk"} and len(ts) < 4:
                continue

            uniq = {pos_key(t["new_position"]) for t in ts}
            # If a crowded type (chairs/desks) collapses into very few targets, treat it as a group move.
            if len(uniq) > max(1, len(ts) // 6):
                continue

            # Need original positions for these objects
            orig_positions = []
            for t in ts:
                obj_key = str(t.get("object_id", "")).lower()
                if obj_key in orig_pos_by_id:
                    orig_positions.append(orig_pos_by_id[obj_key])
            if len(orig_positions) != len(ts):
                continue

            tx = sum(float(t["new_position"]["x"]) for t in ts) / len(ts)
            ty = sum(float(t["new_position"]["y"]) for t in ts) / len(ts)
            ox = sum(p[0] for p in orig_positions) / len(orig_positions)
            oy = sum(p[1] for p in orig_positions) / len(orig_positions)
            dx, dy = (tx - ox), (ty - oy)

            for t in ts:
                obj_key = str(t.get("object_id", "")).lower()
                op = orig_pos_by_id[obj_key]
                t["new_position"] = {"x": op[0] + dx, "y": op[1] + dy}

        def clamp_to_room(x: float, y: float, obj_id_key: str) -> Tuple[float, float]:
            """Clamp position into room bounds, leaving a margin for walls and object footprint."""
            if not room_bounds:
                return (x, y)

            min_x, max_x, min_y, max_y = room_bounds
            length_m, width_m = dims_by_id.get(obj_id_key, (0.8, 0.8))

            # Keep a margin from walls: half footprint + epsilon.
            # Desks/tables need more clearance than chairs.
            obj_type = type_by_id.get(obj_id_key, "")
            extra = 0.25 if obj_type in {"desk", "table"} else 0.12
            wall_margin = max(length_m, width_m) / 2.0 + extra

            cx = min(max(x, min_x + wall_margin), max_x - wall_margin)
            cy = min(max(y, min_y + wall_margin), max_y - wall_margin)
            return (cx, cy)

        # First clamp all suggested targets into room so we don't start outside.
        for t in cleaned:
            obj_key = str(t.get("object_id", "")).lower()
            x0 = float(t["new_position"]["x"])
            y0 = float(t["new_position"]["y"])
            cx, cy = clamp_to_room(x0, y0, obj_key)
            t["new_position"] = {"x": cx, "y": cy}

        # Spread exact/near-duplicate target positions to avoid stacking (chairs/desks/tables commonly collide).
        taken: List[Tuple[float, float, float]] = []  # (x, y, min_dist)

        def dist(a: Tuple[float, float], b: Tuple[float, float]) -> float:
            return math.hypot(a[0] - b[0], a[1] - b[1])

        for t in cleaned:
            obj_key = str(t.get("object_id", "")).lower()
            x = float(t["new_position"]["x"])
            y = float(t["new_position"]["y"])

            length_m, width_m = dims_by_id.get(obj_key, (0.8, 0.8))
            base_sep = max(length_m, width_m, 0.6) * 0.55  # spacing to reduce overlap without pushing outside

            candidate = (x, y)
            collides = any(dist(candidate, (tx, ty)) < max(base_sep, md) for tx, ty, md in taken)
            if collides:
                # Spiral search around the target
                found = False
                for ring in range(1, 25):
                    r = base_sep * ring
                    for angle_deg in (0, 90, 180, 270, 45, 135, 225, 315):
                        ang = math.radians(angle_deg)
                        cand_raw = (x + r * math.cos(ang), y + r * math.sin(ang))
                        cand = clamp_to_room(cand_raw[0], cand_raw[1], obj_key)
                        if all(dist(cand, (tx, ty)) >= max(base_sep, md) for tx, ty, md in taken):
                            candidate = cand
                            found = True
                            break
                    if found:
                        break

                # If we still couldn't find a non-colliding spot, fall back to the original
                # position (preserves layout instead of stacking).
                if not found and obj_key in orig_pos_by_id:
                    candidate = clamp_to_room(orig_pos_by_id[obj_key][0], orig_pos_by_id[obj_key][1], obj_key)

            # Final clamp (in case no suitable free spot was found)
            candidate = clamp_to_room(candidate[0], candidate[1], obj_key)
            t["new_position"] = {"x": float(candidate[0]), "y": float(candidate[1])}
            taken.append((candidate[0], candidate[1], base_sep))

        return cleaned
    
    def _generate_transform_line(self, transform: Dict, existing_transform: Optional[Dict] = None) -> str:
        """
        Generate USD transform operations preserving scale and other properties.
        
        Prefers separate translate/rotate/scale operations over matrix for better preservation.
        """
        new_pos = transform.get("new_position", {})
        new_rot_deg = transform.get("new_rotation_deg", 0)
        
        # RoomPlan/object positions are in the floor plane (X, Y) where USD is XZ with Y-up.
        # So we map:
        # - position.x -> USD X
        # - position.y -> USD Z
        # and preserve the existing USD Y (vertical) translation if present.
        x = float(new_pos.get("x", 0.0))
        z = float(new_pos.get("y", 0.0))
        existing_t = existing_transform.get("translate", (0.0, 0.0, 0.0)) if existing_transform else (0.0, 0.0, 0.0)
        y = float(existing_t[1])  # preserve vertical placement

        # Clamp to floor (prevents sinking beneath ground)
        floor_y = getattr(self, "_current_floor_y", None)
        if isinstance(floor_y, (int, float)):
            y = max(y, float(floor_y) + 0.01)
        
        # Preserve scale from existing transform
        scale = existing_transform.get("scale", (1.0, 1.0, 1.0)) if existing_transform else (1.0, 1.0, 1.0)
        
        # Rotation in RoomPlan is around the vertical axis; USD is Y-up.
        # So we rotate about Y.
        rot_rad = math.radians(float(new_rot_deg))
        
        # If existing transform uses separate operations, prefer that approach
        if existing_transform and (existing_transform.get("has_translate") or existing_transform.get("has_rotate") or existing_transform.get("has_scale")):
            # Use separate operations - more flexible and preserves properties
            lines = []
            if existing_transform.get("has_translate") or True:  # Always set translate
                lines.append(f'double3 xformOp:translate = ({x}, {y}, {z})')
            if existing_transform.get("has_rotate") or True:  # Always set rotation
                lines.append(f'double3 xformOp:rotateXYZ = (0, 0, {new_rot_deg})')
            if existing_transform.get("has_scale"):
                lines.append(f'double3 xformOp:scale = ({scale[0]}, {scale[1]}, {scale[2]})')
            return '\n'.join(lines)
        
        # Otherwise, use matrix but preserve scale
        cos_r = math.cos(rot_rad)
        sin_r = math.sin(rot_rad)
        
        # Create 4x4 transform matrix with preserved scale.
        # USD ASCII here uses row-major rows, with Y-up.
        # Rotation about Y:
        #   [ cos  0  -sin  0 ]
        #   [  0   1   0    0 ]
        #   [ sin  0   cos  0 ]
        #   [ tx  ty   tz   1 ]
        # Format numbers - USD requires all matrix values to have decimal points
        def format_num(val):
            # Always format as float with decimal point for USD compatibility
            # USD parser is strict: all matrix values must have decimal points
            # Format with precision, but ensure decimal point is always present
            if val == int(val):
                # Whole number - format as "1.0" not "1"
                return f"{int(val)}.0"
            else:
                # Decimal number - format with reasonable precision
                formatted = f"{val:.10f}".rstrip('0').rstrip('.')
                # Ensure it still has decimal point after stripping
                if '.' not in formatted:
                    formatted = f"{formatted}.0"
                return formatted
        
        sx, sy, sz = scale
        m00 = format_num(sx * cos_r)
        m02 = format_num(-sx * sin_r)
        m11 = format_num(sy)
        m20 = format_num(sz * sin_r)
        m22 = format_num(sz * cos_r)
        m30 = format_num(x)
        m31 = format_num(y)
        m32 = format_num(z)
        
        # Build matrix rows - ALL values must have decimal points
        row1 = f"({m00}, 0.0, {m02}, 0.0)"
        row2 = f"(0.0, {m11}, 0.0, 0.0)"
        row3 = f"({m20}, 0.0, {m22}, 0.0)"
        row4 = f"({m30}, {m31}, {m32}, 1.0)"
        
        # Match typical USD ASCII formatting: `( (..), (..), (..), (..) )`
        matrix = f"( {row1}, {row2}, {row3}, {row4} )"
        
        return f'matrix4d xformOp:transform = {matrix}'
    
    def _apply_transform_to_xform(
        self, 
        lines: List[str], 
        start_idx: int, 
        end_idx: int,
        xform_name: str,
        transform: Optional[Dict]
    ) -> List[str]:
        """Apply transformation to an Xform block, preserving scale and other properties."""
        if not transform:
            return lines
        
        # Parse existing transform to preserve scale
        existing_transform = self._parse_existing_transform(lines, start_idx, end_idx)
        
        # Generate transform line preserving existing properties
        transform_lines = self._generate_transform_line(transform, existing_transform)
        transform_line_list = transform_lines.split('\n') if '\n' in transform_lines else [transform_lines]
        
        # Find and replace existing transform operations.
        #
        # IMPORTANT: do not remove xformOpOrder separately after removing other lines,
        # otherwise index drift can cause us to delete an unrelated line (often a closing brace),
        # producing parse errors like "Expected } at ''".
        lines_to_remove: List[int] = []
        for i in range(start_idx, min(end_idx + 1, len(lines))):
            line = lines[i]
            if (
                'xformOpOrder' in line
                or any(op in line for op in ['xformOp:transform', 'xformOp:translate', 'xformOp:rotate', 'xformOp:scale', 'matrix4d'])
            ):
                lines_to_remove.append(i)
        
        # Remove old transform lines (in reverse to maintain indices)
        for idx in reversed(lines_to_remove):
            lines.pop(idx)
            # Adjust end_idx if needed
            if idx <= end_idx:
                end_idx -= 1
        
        # Find insertion point - insert right after the opening brace of the Xform
        # IMPORTANT: Do NOT insert inside the prim metadata parentheses "( ... )".
        # Some prim headers span many lines (e.g. long "prepend references" lists),
        # so we must search the entire Xform block for the real opening brace "{".
        insert_idx = None
        indent = 4

        # Find the opening brace and determine indentation.
        # IMPORTANT: Only treat a line that *starts* a prim body as the opening brace,
        # not metadata dict braces like `assetInfo = { ... }`.
        search_end = min(end_idx + 1, len(lines))
        for i in range(start_idx, search_end):
            line = lines[i]
            if '{' in line and line.lstrip().startswith('{'):
                # Found opening brace, insert after this line
                insert_idx = i + 1
                # Get indentation - add 4 spaces for nested content
                base_indent = len(line) - len(line.lstrip())
                indent = base_indent + 4
                break

        # Fallback: if we somehow can't find "{", insert near end of block (before closing brace)
        if insert_idx is None:
            insert_idx = min(end_idx, len(lines))

        # Make sure insert_idx is valid
        insert_idx = max(0, min(insert_idx, len(lines)))
        
        # Determine which transform operations we're using
        uses_matrix = 'matrix4d' in transform_lines or 'xformOp:transform' in transform_lines
        uses_separate = any(op in transform_lines for op in ['xformOp:translate', 'xformOp:rotate', 'xformOp:scale'])
        
        # Add xformOpOrder declaration (USD requires this before transform ops)
        # Insert it first, then the transform operations
        if uses_matrix or uses_separate:
            if uses_matrix:
                op_order = '["xformOp:transform"]'
            else:
                ops = []
                if 'xformOp:translate' in transform_lines:
                    ops.append('"xformOp:translate"')
                if 'xformOp:rotateXYZ' in transform_lines or 'xformOp:rotate' in transform_lines:
                    ops.append('"xformOp:rotateXYZ"')
                if 'xformOp:scale' in transform_lines:
                    ops.append('"xformOp:scale"')
                op_order = f"[{', '.join(ops)}]"
            
            # Insert xformOpOrder first (USD expects this to describe the op stack).
            # Since we insert inside the prim body "{ ... }", we don't need any special
            # safety checks around metadata parentheses.
            try:
                xform_op_order_line = f'{" " * indent}uniform token[] xformOpOrder = {op_order}\n'
                lines.insert(insert_idx, xform_op_order_line)
                insert_idx += 1
                logger.debug(f"Inserted xformOpOrder at line {insert_idx}")
            except Exception as e:
                logger.warning(f"Failed to insert xformOpOrder: {e}. USD may infer transform operations automatically.")
        
        # Insert new transform lines
        for transform_line in reversed(transform_line_list):
            transform_line_with_indent = ' ' * indent + transform_line + '\n'
            lines.insert(insert_idx, transform_line_with_indent)
        
        logger.debug(f"Applied transform for '{xform_name}' (preserved scale: {existing_transform.get('scale', 'unknown')})")
        
        return lines
    
    def _estimate_new_score(self, current_score: int, suggestions: Dict) -> int:
        """Estimate new Feng Shui score based on suggested transformations."""
        transformations = suggestions.get("transformations", [])
        total_improvement = sum(
            t.get("expected_score_improvement", 0) 
            for t in transformations
        )
        
        new_score = min(100, current_score + total_improvement)
        return new_score
